"""Single-task operator simulation. Administrative screens stay in a separate window."""
from uuid import uuid4
from datetime import datetime
from frontend.desktop.date_controls import LOCAL_ZONE
from PySide6.QtCore import QTimer,QThreadPool,QDate
from PySide6.QtWidgets import (
    QMainWindow,QWidget,QVBoxLayout,QHBoxLayout,QFrame,QScrollArea,QProgressBar,
    QPushButton,QSpinBox,QDateEdit,QDialog,QComboBox,QPlainTextEdit,QDialogButtonBox,
)
from frontend.desktop.client import Api
from frontend.desktop.widgets import label,button,number,Job
from frontend.desktop.theme import STYLE

OPERATOR_STYLE = """
QMainWindow, QWidget#operatorShell, QWidget#operatorBody {background: #0F1F2E;}
QScrollArea {background: transparent; border: none;}
QFrame#card {background: #17304A; border: 1px solid #253E57; border-radius: 14px;}
QFrame#operatorLocation {background: #0B2E20; border: 2px solid #007C69; border-radius: 14px;}
QLabel {color: #FFFFFF; background: transparent;}
QLabel#muted, QLabel#operatorRoute {font-size: 14px; color: #A0C8C0;}
QLabel#eyebrow {color: #00D4A8;}
QLabel#operatorProduct {font-size: 29px; font-weight: 700; color: #FFFFFF;}
QLabel#operatorQuantity {font-size: 56px; font-weight: 750; color: #00D4A8;}
QLabel#operatorInstruction {font-size: 24px; font-weight: 700; color: #FFFFFF;}
QLabel#operatorPlace {font-size: 17px; font-weight: 600; color: #A0C8C0;}
QLabel#operatorStatus {font-size: 14px; color: #A0C8C0;}
QPushButton {background: #17304A; color: #A0C8C0; border: 1px solid #253E57; border-radius: 10px;}
QPushButton:hover {background: #1E3A57;}
QPushButton#operatorConfirm {background: #007C69; color: white; border: none; border-radius: 14px; font-size: 19px; padding: 12px;}
QPushButton#operatorConfirm:hover {background: #009A82;}
QPushButton#operatorConfirm:disabled {background: #173A30; color: #A0C8C0;}
QLabel#operatorStep {font-size: 12px; color: #8AAABB; padding: 5px 1px;}
QLabel#operatorActiveStep {font-size: 12px; font-weight: 700; color: #00D4A8; padding: 5px 1px;}
QDateEdit, QSpinBox, QComboBox, QPlainTextEdit {background: #17304A; color: white;}
QDialog {background: #0F1F2E;}
"""



class OperatorWindow(QMainWindow):
    def __init__(self,api=None):
        super().__init__()
        self.api=api or Api()
        self.state={};self.task=None;self.preferred=None;self.pending=None
        self.jobs=set();self.pool=QThreadPool(self);self.admin=None;self.paused=False
        self.setWindowTitle("Mi almacén | Montacarguista")
        self.resize(480,860);self.setMinimumSize(360,620)
        self.setStyleSheet(STYLE+OPERATOR_STYLE)
        shell=QWidget();shell.setObjectName("operatorShell");self.setCentralWidget(shell);layout=QVBoxLayout(shell)
        layout.setContentsMargins(16,14,16,14);layout.setSpacing(10)
        top=QHBoxLayout();top.addWidget(label("MI TAREA","eyebrow"));top.addStretch()
        self.refresh_button=button("Actualizar",self.refresh);top.addWidget(self.refresh_button)
        self.admin_button=button("Supervisor",self.open_admin);top.addWidget(self.admin_button);layout.addLayout(top)
        calendar_row=QHBoxLayout();calendar_row.addWidget(label("Día de trabajo","eyebrow"))
        today=QDate.fromString(datetime.now(LOCAL_ZONE).date().isoformat(),"yyyy-MM-dd")
        self.calendar=QDateEdit(today);self.calendar.setCalendarPopup(True)
        self.calendar.setDisplayFormat("dd/MM/yyyy");self.calendar.setMinimumDate(today)
        calendar_row.addWidget(self.calendar)
        self.today_button=button("Volver a hoy",self.select_today);calendar_row.addWidget(self.today_button)
        layout.addLayout(calendar_row)
        self.calendar.dateChanged.connect(self.change_date)
        self.notice=label("Vista de operador · simulación de escritorio","muted");layout.addWidget(self.notice)
        self.status=label("Buscando tu siguiente tarea…","operatorStatus");layout.addWidget(self.status)
        self.progress=QProgressBar();self.progress.setRange(0,0);self.progress.setFixedHeight(4);self.progress.hide();layout.addWidget(self.progress)
        scroll=QScrollArea();scroll.setWidgetResizable(True)
        body=QWidget();body.setObjectName("operatorBody");content=QVBoxLayout(body)
        content.setContentsMargins(0,0,0,0);content.setSpacing(12);scroll.setWidget(body);layout.addWidget(scroll,1)
        steps=QHBoxLayout();self.steps=[]
        for text in ("1 Recoger","2 Empacar","3 Llevar","4 Cargar"):
            item=label(text,"operatorStep");steps.addWidget(item);self.steps.append(item)
        content.addLayout(steps)
        card=QFrame();card.setObjectName("card");self.card_layout=QVBoxLayout(card)
        self.card_layout.setContentsMargins(18,16,18,16);self.card_layout.setSpacing(8)
        self.heading=label("Espera un momento","operatorInstruction");self.card_layout.addWidget(self.heading)
        self.product=label("","operatorProduct");self.card_layout.addWidget(self.product)
        self.quantity_label=label("","operatorQuantity");self.card_layout.addWidget(self.quantity_label)
        self.store=label("","operatorRoute");self.card_layout.addWidget(self.store)
        content.addWidget(card)
        self.places=QFrame();self.places.setObjectName("operatorLocation");places=QVBoxLayout(self.places)
        places.setContentsMargins(18,14,18,14);places.setSpacing(7)
        self.source_caption=label("RECOGE EN","eyebrow");places.addWidget(self.source_caption)
        self.source=label("","operatorPlace");places.addWidget(self.source);places.addSpacing(9)
        self.destination_caption=label("LLEVA A","eyebrow");places.addWidget(self.destination_caption)
        self.destination=label("","operatorPlace");places.addWidget(self.destination);content.addWidget(self.places)
        self.reference=label("","muted");content.addWidget(self.reference)
        self.adjust_button=button("Voy a confirmar otra cantidad",self.toggle_quantity);content.addWidget(self.adjust_button)
        self.quantity=QSpinBox();self.quantity.setSuffix(" piezas");self.quantity.setMinimumHeight(44)
        self.quantity.valueChanged.connect(self.update_confirm);self.quantity.hide();content.addWidget(self.quantity)
        content.addStretch()
        self.confirm=button("Actualizar tareas",self.confirm_task);self.confirm.setObjectName("operatorConfirm")
        self.confirm.setMinimumHeight(62);layout.addWidget(self.confirm)
        self.problem=button("No puedo continuar",self.report_problem);self.problem.setMinimumHeight(44);layout.addWidget(self.problem)
        self.hint=label("Confirma cada paso solo después de realizarlo.","muted");layout.addWidget(self.hint)
        self.day_timer=QTimer(self);self.day_timer.setInterval(60000);self.day_timer.timeout.connect(self.check_day);self.day_timer.start()
        QTimer.singleShot(0,self.refresh)

    def run(self,fn,done):
        if self.jobs:return
        def safe():
            try:return dict(ok=True,value=fn())
            except Exception as error:return dict(ok=False,error=str(error),status=getattr(error,"status_code",None))
        job=Job(safe);self.jobs.add(job);self.progress.show()
        for w in (self.confirm,self.problem,self.refresh_button,self.admin_button,self.adjust_button,self.quantity,self.calendar,self.today_button):w.setEnabled(False)
        def finish(result):
            self.jobs.discard(job);self.progress.hide()
            for w in (self.refresh_button,self.admin_button,self.adjust_button,self.quantity,self.calendar,self.today_button):w.setEnabled(True)
            if result["ok"]:
                done(result["value"])
            else:
                self.status.setText(result["error"])
                if self.pending and result.get("status") in (400,401,403,404,409,422):
                    self.pending=None;self.task=None;self.confirm.setText("Actualizar tareas")
                    self.confirm.setEnabled(True);self.problem.setEnabled(False)
                elif self.pending:
                    self.confirm.setText("Reintentar confirmación");self.confirm.setEnabled(True)
                    self.problem.setEnabled(False);self.refresh_button.setEnabled(False)
                    self.calendar.setEnabled(False);self.today_button.setEnabled(False)
                    self.admin_button.setEnabled(False);self.adjust_button.setEnabled(False);self.quantity.setEnabled(False)
                else:
                    # Do not enable an old instruction after a failed refresh.
                    self.task=None;self.confirm.setText("Actualizar tareas");self.confirm.setEnabled(True);self.problem.setEnabled(False)
        job.signals.done.connect(finish);self.pool.start(job)

    def refresh(self):
        if self.pending or self.paused:return
        today=QDate.fromString(datetime.now(LOCAL_ZONE).date().isoformat(),"yyyy-MM-dd")
        self.calendar.blockSignals(True);self.calendar.setMinimumDate(today);self.calendar.blockSignals(False)
        params={} if self.preferred is None else {"preferred_allocation":self.preferred}
        params["selected_date"]=self.calendar.date().toString("yyyy-MM-dd")
        self.run(lambda:self.api.request("GET","/demo/operator",params=params),self.render)

    def render(self,state):
        if state.get("today"):
            self.calendar.blockSignals(True)
            self.calendar.setMinimumDate(QDate.fromString(state["today"],"yyyy-MM-dd"))
            self.calendar.setDate(QDate.fromString(state["selected_date"],"yyyy-MM-dd"))
            self.calendar.blockSignals(False)
        self.state=state;self.task=state.get("task");self.quantity.hide();self.paused=False
        task=self.task
        self.places.setVisible(task is not None);self.adjust_button.setVisible(bool(task and task["can_adjust"]))
        self.problem.setVisible(task is not None);self.problem.setEnabled(task is not None)
        if not task:
            self.heading.setText("Por ahora, todo listo");self.product.setText(state["message"])
            self.quantity_label.setText("");self.store.setText("");self.reference.setText("")
            self.confirm.setText("Buscar siguiente tarea");self.confirm.setEnabled(True)
        else:
            self.preferred=task["allocation_id"]
            titles={"pick":"Recoge este producto","pack":"Empaca lo que recogiste","stage":"Lleva esta tarima","load":"Carga esta tarima"}
            self.heading.setText(titles[task["action"]]);self.product.setText(task["product"])
            self.quantity_label.setText(f'{number(task["quantity"])} piezas')
            self.store.setText("Para: "+task["store"])
            self.source_caption.setText("RECOGE EN" if task["action"]=="pick" else "LO RECOGISTE EN" if task["action"]=="pack" else "TARIMA EN")
            self.source.setText(task["source"]);self.destination.setText(task["destination"])
            self.destination_caption.setText("EMPACA EN" if task["action"]=="pack" else "LLEVA A")
            reference="Pedido "+task["order"]
            if task.get("scheduled_date"):reference+="\nDía planeado: "+task["scheduled_date"]+" · reloj simulado"
            if task.get("hu"):reference+="\nTarima "+task["hu"]
            self.reference.setText(reference)
            self.quantity.blockSignals(True);self.quantity.setRange(1,task["quantity"]);self.quantity.setValue(task["quantity"]);self.quantity.blockSignals(False)
            self.update_confirm();self.confirm.setEnabled(True)
        for i,item in enumerate(self.steps,1):
            item.setObjectName("operatorActiveStep" if task and task["step"]==i else "operatorStep")
            item.style().unpolish(item);item.style().polish(item)
        if state.get("read_only"):
            self.heading.setText("Próximas tareas · solo consulta")
            self.product.setText("\n\n".join(f'{r["quantity"]} piezas · {r["product"]}\nPara: {r["store"]}\nEn: {r["source"]}' for r in state.get("preview",[])) or "No hay tareas programadas para este día.")
            self.confirm.hide();self.adjust_button.hide();self.problem.hide()
            self.status.setText("Puedes consultar este día, pero no confirmar trabajo.")
        else:
            self.confirm.show()
            self.status.setText("Trabajo de hoy, incluidos pendientes anteriores.")
        if self.status.text().startswith("Buscando"):self.status.setText("Una tarea a la vez. Los datos ya están completos.")

    def check_day(self):
        if not self.jobs and not self.pending and self.state.get("today")!=datetime.now(LOCAL_ZONE).date().isoformat():
            self.paused=False;self.refresh()

    def select_today(self):
        self.calendar.setDate(QDate.fromString(self.state.get("today",QDate.currentDate().toString("yyyy-MM-dd")),"yyyy-MM-dd"))

    def change_date(self):
        if self.jobs or self.pending:return
        self.preferred=None;self.paused=False;self.refresh()

    def toggle_quantity(self):
        self.quantity.setVisible(not self.quantity.isVisible())
        if self.quantity.isVisible():self.quantity.setFocus()

    def update_confirm(self):
        if not self.task or self.pending:return
        qty=self.quantity.value()
        texts={"pick":f"Ya recogí {number(qty)} piezas","pack":f"Ya empaqué {number(qty)} piezas",
               "stage":"Ya la dejé en el área de salida","load":"Ya cargué la tarima"}
        self.confirm.setText(texts[self.task["action"]])

    def confirm_task(self):
        if self.jobs or self.state.get("read_only"):return
        if self.paused:
            self.paused=False;self.status.setText("Consulta la indicación del supervisor antes de continuar.");self.refresh();return
        if self.pending:
            self.send_pending();return
        if not self.task:self.refresh();return
        payload=dict(self.task["payload"],operator_date=self.state.get("today",self.calendar.date().toString("yyyy-MM-dd")))
        if self.task["can_adjust"]:payload["quantity"]=self.quantity.value()
        self.pending=dict(action=self.task["action"],key=str(uuid4()),payload=payload)
        self.send_pending()

    def send_pending(self):
        request=dict(self.pending)
        def done(result):
            self.pending=None
            if request["action"]=="incident":
                self.paused=True;self.status.setText("Incidencia registrada. Avisa al supervisor. Esta pantalla quedó en pausa.")
                self.confirm.setText("Reanudar después de revisar");self.confirm.setEnabled(True);self.problem.setEnabled(False)
                self.adjust_button.setEnabled(False);self.quantity.setEnabled(False);return
            messages={"pick":"Recogida guardada. Sigue el próximo paso.","pack":"Empaque guardado. Lleva la tarima al área de salida.",
                      "stage":"Traslado guardado. Buscando tu siguiente tarea.","load":"Carga guardada. Buscando tu siguiente tarea."}
            self.status.setText(messages[request["action"]])
            self.task=None;self.refresh()
        self.run(lambda:self.api.request("POST","/demo/operator/commands/"+request["action"],
            json={"key":request["key"],"payload":request["payload"]}),done)

    def report_problem(self):
        if not self.task or self.jobs or self.pending:return
        dialog=QDialog(self);dialog.setWindowTitle("Reportar problema");dialog.setMinimumWidth(320)
        layout=QVBoxLayout(dialog);layout.addWidget(label(self.task["product"],"section"))
        reason=QComboBox();reason.addItems(["Falta producto","Producto dañado","No encuentro la ubicación","Otro problema"]);layout.addWidget(reason)
        note=QPlainTextEdit();note.setPlaceholderText("Detalle opcional");note.setMaximumHeight(100);layout.addWidget(note)
        layout.addWidget(label("Se registra una incidencia y esta pantalla queda en pausa. Avisa al supervisor.","muted"))
        controls=QDialogButtonBox(QDialogButtonBox.StandardButton.Ok|QDialogButtonBox.StandardButton.Cancel)
        controls.button(QDialogButtonBox.StandardButton.Ok).setText("Registrar problema")
        controls.button(QDialogButtonBox.StandardButton.Cancel).setText("Volver")
        controls.accepted.connect(dialog.accept);controls.rejected.connect(dialog.reject);layout.addWidget(controls)
        if dialog.exec()==QDialog.DialogCode.Accepted:
            text=f'{reason.currentText()} · {self.task["product"]} · {note.toPlainText().strip()}'[:1000]
            self.pending=dict(action="incident",key=str(uuid4()),payload=dict(id=self.task["line_id"],reason=text,operator_date=self.state.get("today",self.calendar.date().toString("yyyy-MM-dd"))));self.send_pending()

    def open_admin(self):
        if self.jobs or self.pending:return
        if self.admin is None:
            from frontend.desktop.window import Window
            self.admin=Window(self.api)
            self.admin.operator_requested.connect(self.return_to_operator)
            self.admin.setWindowTitle("Mi almacén | Supervisión (demo)")
            self.admin.statusBar().addPermanentWidget(button("Volver al montacarguista",self.return_to_operator))
            self.admin.nav.setCurrentRow(0)
        self.admin.show();self.admin.raise_();self.admin.activateWindow();self.admin.refresh()

    def return_to_operator(self):
        if self.admin and self.admin.jobs:return
        if self.admin:self.admin.hide()
        self.showNormal();self.raise_();self.activateWindow();self.refresh()

    def closeEvent(self,event):
        if self.jobs or (self.admin and self.admin.jobs):
            self.status.setText("Espera a que termine el guardado antes de cerrar.");event.ignore();return
        if self.pending:
            self.status.setText("Reintenta la confirmación antes de cerrar para comprobar si se guardó.");event.ignore();return
        if self.admin:self.admin.close()
        event.accept()
