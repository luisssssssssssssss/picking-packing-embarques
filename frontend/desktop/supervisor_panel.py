"""A morning briefing for supervisors, using the backend's daily read model."""
from frontend.desktop.widgets import *
from PySide6.QtWidgets import QComboBox


class SupervisorPanel(QWidget):
    def __init__(self, owner):
        super().__init__()
        self.owner=owner
        v=QVBoxLayout(self);v.setContentsMargins(0,0,0,0);v.setSpacing(14)
        hero,c=owner.card();hero.setObjectName("hero")
        self.heading=label("Cargando el trabajo de hoy…","title");c.addWidget(self.heading)
        self.summary=label("","subtitle");c.addWidget(self.summary)
        self.freshness=label("Esperando conexión","muted");c.addWidget(self.freshness)
        self.latest=label("","muted");c.addWidget(self.latest)
        self.operator_button=button("Abrir pantalla del montacarguista",owner.operator_requested.emit,True)
        self.operator_button.setMinimumHeight(48);c.addWidget(self.operator_button);v.addWidget(hero)
        row=QHBoxLayout();self.values={}
        for key,title in [("programado","Programadas hoy"),("recoger","Faltan por recoger¹"),("listo","Ya puedes empacar¹"),("empacado","Empacadas del plan de hoy")]:
            f,c=owner.card();c.addWidget(label(title,"cardLabel"))
            value=label("—","metric");c.addWidget(value);self.values[key]=value;row.addWidget(f)
        v.addLayout(row)
        self.alerts=label("","route")
        actions=QHBoxLayout()
        actions.addWidget(button("Importar CSV o TXT",owner.csv_dialog))
        actions.addWidget(button("Organizar pendientes",lambda:owner.nav.setCurrentRow(1)))
        actions.addWidget(button("Ver preparación",lambda:owner.nav.setCurrentRow(2),True))
        actions.addWidget(button("Revisar viajes",lambda:owner.nav.setCurrentRow(3)))
        actions.addStretch()
        self.handoffs=label("","route");v.addWidget(self.handoffs)
        filters=QHBoxLayout();filters.addWidget(label("Trabajo programado · todas las fechas","section"),1)
        self.filter=QComboBox();self.filter.addItems(["Solo pendientes","Listo para empacar","Todas las tareas"])
        filters.addWidget(self.filter);v.addLayout(filters)
        self.task_rows=[]
        self.filter.currentIndexChanged.connect(self.filter_tasks)
        self.queue=DataTable([("id_pedido","ID pedido"),("descripcion","Producto"),("destino","Entregar en"),("fecha","Día programado"),("periodo","Cuándo"),("por_recoger","Recoger"),("listo_empacar","Empacar ahora"),("situacion","Siguiente paso"),("responsable","Asignado a")])
        self.queue.setMinimumHeight(200);v.addWidget(self.queue)
        self.queue.add_dates(v,"fecha","Filtrar lista; indicadores de arriba siguen siendo de hoy")
        self.empty=label("","muted");v.addWidget(self.empty)
        v.addLayout(actions);v.addWidget(self.alerts)
        row=QHBoxLayout()
        f,c=owner.card();c.addWidget(label("¿Alcanza el inventario?","section"))
        c.addWidget(label("Existencias físicas pendientes de registrar","section"))
        c.addWidget(label("Todavía no podemos confirmar si alcanza. Las piezas pedidas, recogidas o empacadas no son el stock disponible.","muted"));row.addWidget(f)
        f,c=owner.card();c.addWidget(label("Capacidad de surtido de hoy","section"))
        self.capacity=label("—","section");c.addWidget(self.capacity)
        c.addWidget(label("Esta capacidad corresponde a recoger productos. No mide la capacidad de empaque ni garantiza existencias.","muted"));row.addWidget(f);v.addLayout(row)
        v.addWidget(label("Equipo · últimas confirmaciones","section"))
        v.addWidget(label("La demo usa una cuenta compartida. Aquí ves acciones guardadas, no presencia en línea ni actividad individual de cada montacarguista.","muted"))
        self.activity=DataTable([("id_pedido","ID pedido"),("hora","Fecha / hora local"),("responsable","Registrado por"),("accion","Acción"),("detalle","Resultado")])
        self.activity.setMinimumHeight(200);v.addWidget(self.activity)
        self.activity.add_dates(v,"fecha","Últimas 8 acciones; historial completo en Ver historial")
        v.addWidget(label("¹ Incluye pendientes de días anteriores. El avance corresponde al día programado; una confirmación puede haberse realizado en otra fecha.","muted"))

    def render(self, summary):
        if not summary:
            self.heading.setText("Resumen diario no disponible")
            return
        self.heading.setText("Hoy · "+summary["fecha"])
        m=summary["metrics"]
        for key,w in self.values.items():w.setText(number(m[key]))
        remaining=max(0,m["programado"]-m["empacado"])
        self.summary.setText(f'{number(remaining)} piezas pendientes del plan de hoy · {number(m["atraso"])} atrasadas')
        self.freshness.setText("Última lectura: "+summary["actualizado"][11:19]+" · Actualización cada 10 s · Ciudad de México (UTC−06)")
        self.alerts.setText(f'Atención: {number(summary["sin_programar"])} piezas con entrega vencida o de hoy aún sin programar.  |  Inventario sin verificar.')
        self.task_rows=summary.get("all_tasks",summary["tasks"]);self.filter_tasks()
        h=summary.get("handoffs",{})
        self.handoffs.setText(f'Tarimas · {h.get("to_stage",0)} por llevar a salida  ·  {h.get("waiting_trip",0)} sin viaje  ·  {h.get("to_load",0)} por cargar  |  Todos los días')

        cap=summary["capacidad"]
        self.capacity.setText("Sin capacidad programada para hoy" if cap is None else f'{number(summary["reservado"])} / {number(cap)} piezas reservadas')
        self.activity.populate(summary["activity"])
        last=summary["activity"][0] if summary["activity"] else None
        self.latest.setText("Última confirmación: "+last["hora"]+" · "+last["accion"]+" · Cuenta demo compartida" if last else "Equipo: todavía no hay confirmaciones operativas.")

        if not summary["activity"]:
            self.activity.setRowCount(0)
            self.activity.setToolTip("Todavía no hay confirmaciones operativas.")

    def filter_tasks(self):
        index=self.filter.currentIndex()
        rows=[r for r in self.task_rows if index==2 or (r["pendiente"]>0 if index==0 else r["listo_empacar"]>0)]
        self.queue.populate(rows)
        self.empty.setText("" if rows else "No hay tareas para este filtro. Puedes revisar todas las tareas o los pedidos sin programar.")
