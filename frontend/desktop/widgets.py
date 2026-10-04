"""Native Python/Qt desktop workspace for the simulated warehouse journey."""
from datetime import date
from pathlib import Path
import traceback
from PySide6.QtCore import Qt,QObject,QRunnable,QThreadPool,Signal,QDate,QTimer,QPropertyAnimation,QEasingCurve
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
        super().__init__(0,len(columns));self.columns=columns;self.source_rows=[];self.date_controls=None
        self.setHorizontalHeaderLabels([title for _,title in columns])
        self.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.setAlternatingRowColors(True);self.setShowGrid(False)
        self.verticalHeader().hide();self.verticalHeader().setDefaultSectionSize(44)
        self.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.setMinimumHeight(160)
    def add_dates(self,layout,key,caption,utc=False):
        from frontend.desktop.date_controls import DateControls
        self.date_controls=DateControls(self,key,caption,utc)
        layout.insertWidget(layout.indexOf(self),self.date_controls)
        return self.date_controls

    def populate(self,rows):
        self.source_rows=list(rows)
        if self.date_controls:rows=self.date_controls.apply(self.source_rows)
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
                if key.startswith("fecha") or key=="apertura": value=value[:19].replace("T"," ")
                item=QTableWidgetItem(value);item.setData(Qt.ItemDataRole.UserRole,row)
                if key=="id_pedido":
                    item.setToolTip(value)
                    font=item.font();font.setBold(True);item.setFont(font)
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

class StageBar(QWidget):
    """Single stage row: icon + label + animated progress bar + counter."""
    def __init__(self,icon:str,label_text:str,color:str):
        super().__init__()
        self._color=color
        layout=QHBoxLayout(self)
        layout.setContentsMargins(0,0,0,0)
        layout.setSpacing(10)

        # Icon circle
        self._icon_lbl=QLabel(icon)
        self._icon_lbl.setObjectName("stageIcon")
        self._icon_lbl.setFixedSize(32,32)
        self._icon_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self._icon_lbl.setStyleSheet(
            f"background:{color}22;color:{color};border-radius:16px;"
            "font-size:16px;font-weight:bold;"
        )
        layout.addWidget(self._icon_lbl)

        # Stage name
        name=QLabel(label_text)
        name.setObjectName("stageLabel")
        name.setFixedWidth(90)
        layout.addWidget(name)

        # Progress bar
        self._bar=QProgressBar()
        self._bar.setRange(0,1000)   # Use 1000 steps for smooth animation
        self._bar.setValue(0)
        self._bar.setFixedHeight(10)
        self._bar.setTextVisible(False)
        self._bar.setStyleSheet(
            f"QProgressBar{{background:#EEF2F7;border:none;border-radius:5px;}}"
            f"QProgressBar::chunk{{background:{color};border-radius:5px;}}"
        )
        layout.addWidget(self._bar,1)

        # Counter text  e.g. "450 / 1 600"
        self._counter=QLabel("—")
        self._counter.setObjectName("stageCounter")
        self._counter.setFixedWidth(130)
        self._counter.setAlignment(Qt.AlignmentFlag.AlignRight|Qt.AlignmentFlag.AlignVCenter)
        layout.addWidget(self._counter)

        # Percent label
        self._pct=QLabel("0 %")
        self._pct.setObjectName("stagePct")
        self._pct.setFixedWidth(42)
        self._pct.setAlignment(Qt.AlignmentFlag.AlignRight|Qt.AlignmentFlag.AlignVCenter)
        self._pct.setStyleSheet(f"color:{color};font-weight:bold;")
        layout.addWidget(self._pct)

        # Animation
        self._anim=QPropertyAnimation(self._bar,b"value",self)
        self._anim.setDuration(600)
        self._anim.setEasingCurve(QEasingCurve.Type.OutCubic)

    def update_value(self,done:int,total:int):
        pct=min(done,total)/total if total else 0.0
        target=int(pct*1000)
        self._anim.stop()
        self._anim.setEndValue(target)
        self._anim.start()
        self._counter.setText(f"{done:,.0f} / {total:,.0f}")
        self._pct.setText(f"{pct*100:.0f} %")
        # Dim icon when nothing to do
        opacity="FF" if total else "44"
        self._icon_lbl.setStyleSheet(
            f"background:{self._color}{opacity[:2]}22;color:{self._color};border-radius:16px;"
            "font-size:16px;font-weight:bold;"
        )


class StageProgress(QFrame):
    """Card showing the 5-stage warehouse flow with real progress from the snapshot."""
    _STAGES=[
        ("📦", "Pedido",   "#5B7FD4"),
        ("🔍", "Picking",  "#D47F1E"),
        ("📫", "Packing",  "#9B5BD4"),
        ("🚚", "Staging",  "#1E9BAD"),
        ("✅", "Embarque", "#27A06A"),
    ]

    def __init__(self):
        super().__init__()
        self.setObjectName("card")
        outer=QVBoxLayout(self)
        outer.setContentsMargins(20,16,20,16)
        outer.setSpacing(10)

        header=QHBoxLayout()
        title=QLabel("Avance del flujo")
        title.setObjectName("section")
        header.addWidget(title)
        header.addStretch()
        self._total_lbl=QLabel("")
        self._total_lbl.setObjectName("eyebrow")
        header.addWidget(self._total_lbl)
        outer.addLayout(header)

        self._bars:list[StageBar]=[]
        for icon,name,color in self._STAGES:
            bar=StageBar(icon,name,color)
            outer.addWidget(bar)
            self._bars.append(bar)

    def update_totals(self,totals:dict):
        total   =totals.get("cantidad",0)  or 0
        planeado=totals.get("planeado",0)  or 0
        recogido=totals.get("recogido",0)  or 0
        empacado=totals.get("empacado",0)  or 0
        embarcado=totals.get("embarcado",0) or 0

        self._bars[0].update_value(total,    total)       # Pedido  — siempre 100 % si hay pedidos
        self._bars[1].update_value(planeado, total)       # Picking planeado
        self._bars[2].update_value(recogido, total)       # Picking confirmado
        self._bars[3].update_value(empacado, total)       # Packing
        self._bars[4].update_value(embarcado,total)       # Embarque

        overall=int(embarcado/total*100) if total else 0
        self._total_lbl.setText(f"COMPLETADO {overall} %" if total else "SIN PEDIDOS")


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


    def command(self,action,on_success=None,**payload):
        def completed(result):
            self.toast.setText(result.get("message","Operación completada."))
            if on_success:
                on_success(result)
            self.refresh()
        self.run(lambda:self.api.command(action,**payload),completed)


    def open_csv(self):
        path,_=QFileDialog.getOpenFileName(self,"Seleccionar CSV o TXT","","Archivos de pedidos (*.csv *.txt)")
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
        choices=[f"{r.get('id_pedido',r['pedido'])} · línea {r['linea']} · {r['material']}" for r in lines]
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
