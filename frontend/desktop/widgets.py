"""Native Python/Qt desktop workspace for the simulated warehouse journey."""
from datetime import date
from pathlib import Path
import traceback
from PySide6.QtCore import Qt,QObject,QRunnable,QThreadPool,Signal,QDate,QTimer
from PySide6.QtGui import QColor,QFont
from PySide6.QtWidgets import (
 QApplication,QMainWindow,QWidget,QFrame,QHBoxLayout,QVBoxLayout,QGridLayout,QLabel,
 QListWidget,QStackedWidget,QPushButton,QTableWidget,QTableWidgetItem,QHeaderView,
 QAbstractItemView,QProgressBar,QPlainTextEdit,QFileDialog,QMessageBox,QDialog,
 QDialogButtonBox,QFormLayout,QSpinBox,QLineEdit,QDateEdit,QScrollArea,
)
from frontend.desktop.client import Api
from frontend.desktop.theme import STYLE

def label(text,name=None):
    result=QLabel(text)
    if name: result.setObjectName(name)
    result.setTextFormat(Qt.TextFormat.PlainText)
    result.setWordWrap(name not in ("eyebrow","badge","brand","brandSub"))
    return result

def button(text,callback,primary=False):
    result=QPushButton(text)
    if primary: result.setObjectName("primary")
    result.clicked.connect(callback)
    return result

def number(value):
    return f"{float(value or 0):,.0f}"

STATES={"CREATED":"Nuevo","RELEASED":"Liberado","OPEN":"Pendiente","ASSIGNED":"Asignado",
        "IN_PROGRESS":"En proceso","COMPLETED":"Completado","PACKED":"Empacada","STAGED":"Preembarque",
        "LOADED":"Cargada","SHIPPED":"Embarcada","LOADING":"En carga","CLOSED":"Cerrado","FAILED":"Rechazado",
        "DISPATCHED":"Despachada","RESOLVED":"Resuelta"}

class Signals(QObject):
    done=Signal(object)
    error=Signal(str)

class Job(QRunnable):
    def __init__(self,fn):
        super().__init__(); self.fn=fn; self.signals=Signals()
    def run(self):
        try: self.signals.done.emit(self.fn())
        except Exception as error: self.signals.error.emit(str(error))

class DataTable(QTableWidget):
    def __init__(self,columns):
        super().__init__(0,len(columns));self.columns=columns
        self.setHorizontalHeaderLabels([title for _,title in columns])
        self.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.setAlternatingRowColors(True);self.setShowGrid(False)
        self.verticalHeader().hide();self.verticalHeader().setDefaultSectionSize(44)
        self.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.setMinimumHeight(160)
    def populate(self,rows):
        self.blockSignals(True)
        previous=self.selected()
        self.clearSelection()
        self.setCurrentCell(-1,-1)
        self.setRowCount(len(rows))
        for idx,row in enumerate(rows):
            for col,(key,title) in enumerate(self.columns):
                value=row.get(key,"")
                if value is None: value="—"
                elif isinstance(value,(float,int)) and key not in ("id","parada","shipment_id"): value=number(value)
                elif key in ("estado",): value=STATES.get(str(value),str(value))
                else: value=str(value)
                if key=="km" and isinstance(row.get(key),(int,float)):
                    value=f"{row[key]:g} km"
                if key in ("fecha","apertura"): value=value[:19].replace("T"," ")
                item=QTableWidgetItem(value);item.setData(Qt.ItemDataRole.UserRole,row)
                if key=="estado":
                    item.setForeground(QColor("#008575" if row.get(key) not in ("FAILED","OPEN") else "#AD7621"))
                    font=item.font();font.setBold(True);item.setFont(font)
                self.setItem(idx,col,item)
            if previous and previous.get("id")==row.get("id"): self.selectRow(idx)
        if rows and self.currentRow()<0: self.selectRow(0)
        self.blockSignals(False)
        self.itemSelectionChanged.emit()
    def selected(self):
        idx=self.currentRow()
        return self.item(idx,0).data(Qt.ItemDataRole.UserRole) if idx>=0 and self.item(idx,0) else None

class WindowSupport:
    def card(self):
        f=QFrame();f.setObjectName("card");v=QVBoxLayout(f);v.setContentsMargins(20,17,20,17);v.setSpacing(10);return f,v


    def run(self,fn,done):
        if self.jobs: return
        job=Job(fn);self.jobs.add(job);self.progress.show();self.pages.setEnabled(False)
        def finish(value,error=False):
            self.jobs.discard(job);self.progress.hide();self.pages.setEnabled(True)
            if error:
                self.toast.setText("No se pudo completar: "+str(value))
                QMessageBox.warning(self,"Revisar operación",str(value))
            else: done(value)
        job.signals.done.connect(lambda value:finish(value))
        job.signals.error.connect(lambda value:finish(value,True))
        self.pool.start(job)


    def refresh(self):
        self.run(self.api.snapshot,self.render)


    def form(self,title,description,fields):
        dialog=QDialog(self);dialog.setWindowTitle(title);dialog.setMinimumWidth(480)
        layout=QVBoxLayout(dialog);layout.addWidget(label(title,"section"));layout.addWidget(label(description,"muted"))
        form=QFormLayout();widgets={}
        for key,caption,value in fields:
            if isinstance(value,int):
                widget=QSpinBox();widget.setRange(1,max(1,value));widget.setValue(max(1,value))
            else:
                widget=QLineEdit(str(value));widget.setMaxLength(1000)
            form.addRow(caption,widget);widgets[key]=widget
        layout.addLayout(form)
        buttons=QDialogButtonBox(QDialogButtonBox.StandardButton.Ok|QDialogButtonBox.StandardButton.Cancel)
        buttons.button(QDialogButtonBox.StandardButton.Ok).setText(title)
        buttons.button(QDialogButtonBox.StandardButton.Cancel).setText("Volver")
        buttons.accepted.connect(dialog.accept);buttons.rejected.connect(dialog.reject);layout.addWidget(buttons)
        if dialog.exec()!=QDialog.DialogCode.Accepted: return None
        return {key:w.value() if isinstance(w,QSpinBox) else w.text() for key,w in widgets.items()}


    def command(self,action,**payload):
        def completed(result):
            self.toast.setText(result.get("message","Operación completada."))
            self.refresh()
        self.run(lambda:self.api.command(action,**payload),completed)


    def open_csv(self):
        path,_=QFileDialog.getOpenFileName(self,"Seleccionar CSV","","CSV (*.csv)")
        if not path:return
        try:
            if Path(path).stat().st_size>1_000_000: raise ValueError("La demo admite archivos de hasta 1 MB.")
            # Opaque preview/upload; column parsing and validation belong to the API.
            self.csv.setPlainText(Path(path).read_text(encoding="utf-8-sig"));self.filename.setText(Path(path).name)
        except (OSError,UnicodeError,ValueError) as e: QMessageBox.warning(self,"No se pudo abrir",str(e))


    def import_csv(self):
        self.command("import",content=self.csv.toPlainText(),filename=self.filename.text())


    def manifest(self):
        row=self.selected(self.shipments)
        if not row:return
        def show(result):
            dialog=QDialog(self);dialog.setWindowTitle("Manifiesto de embarque");dialog.resize(760,580)
            layout=QVBoxLayout(dialog);text=QPlainTextEdit();text.setReadOnly(True)
            import json
            text.setPlainText(json.dumps(result,ensure_ascii=False,indent=2));layout.addWidget(text)
            layout.addWidget(button("Cerrar",dialog.accept));dialog.exec()
        self.run(lambda:self.api.request("GET",f"/demo/shipments/{row['id']}/manifest"),show)


    def incident(self):
        lines=self.state.get("lines",[])
        if not lines:
            QMessageBox.information(self,"Incidencias","Importa un pedido antes de registrar una incidencia.");return
        from PySide6.QtWidgets import QInputDialog
        choices=[f"{r['pedido']} · línea {r['linea']} · {r['material']}" for r in lines]
        choice,ok=QInputDialog.getItem(self,"Pedido afectado","Selecciona la línea:",choices,0,False)
        if not ok:return
        row=lines[choices.index(choice)]
        data=self.form("Registrar incidencia",choice+"\nSe registra como observación; no bloquea el pedido automáticamente.",[("reason","Descripción","")])
        if data:self.command("incident",id=row["id"],**data)


    def closeEvent(self,event):
        if self.jobs:
            QMessageBox.information(self,"Operación en curso","Espera a que termine la operación antes de cerrar.")
            event.ignore()
        else:event.accept()
