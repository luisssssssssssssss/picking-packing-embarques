"""Guided native desktop demo: recognizable products and one suggested next action."""
from datetime import date
from PySide6.QtWidgets import QComboBox,QDoubleSpinBox
from frontend.desktop.widgets import *


class Window(WindowSupport,QMainWindow):
    operator_requested=Signal()
    def __init__(self,api=None):
        super().__init__()
        self.api=api or Api();self.state={};self.jobs=set();self.pool=QThreadPool(self)
        self.setWindowTitle("Mi almacén | Demo de tiendas")
        self.resize(1380,900);self.setMinimumSize(1050,740);self.setStyleSheet(STYLE)
        shell=QWidget();self.setCentralWidget(shell)
        outer=QHBoxLayout(shell);outer.setContentsMargins(0,0,0,0);outer.setSpacing(0)
        side=QFrame();side.setObjectName("sidebar");side.setFixedWidth(210)
        sl=QVBoxLayout(side);sl.setContentsMargins(18,30,18,24)
        sl.addWidget(label("MI ALMACÉN","brand"));sl.addWidget(label("SURTIR. EMPACAR. ENTREGAR.","brandSub"));sl.addSpacing(30)
        self.nav=QListWidget();self.nav.setObjectName("nav")
        self.nav.addItems(["Hoy","Pedidos","Preparar productos","Viajes","Destinos"])
        sl.addWidget(self.nav,1)
        sl.addWidget(button("Ver historial",self.history))
        sl.addWidget(label("DEMO DE TIENDAS\n\nProductos conocidos.\nDatos ficticios.\nMovimientos guardados.","navFooter"))
        outer.addWidget(side)
        work=QWidget();work.setObjectName("workspace");wl=QVBoxLayout(work)
        wl.setContentsMargins(30,24,30,20);wl.setSpacing(12);outer.addWidget(work,1)
        top=QHBoxLayout();top.addWidget(label("TU OPERACIÓN, PASO A PASO","eyebrow"));top.addStretch()
        top.addWidget(label("EJEMPLO · TIPO OXXO","badge"));top.addWidget(button("Actualizar",self.refresh));wl.addLayout(top)
        self.title=label("Todo listo para continuar","title");self.subtitle=label("","subtitle")
        wl.addWidget(self.title);wl.addWidget(self.subtitle)
        self.progress=QProgressBar();self.progress.setRange(0,0);self.progress.setFixedHeight(4);self.progress.hide();wl.addWidget(self.progress)
        self.pages=QStackedWidget();wl.addWidget(self.pages,1)
        self.toast=label("Conectando con tu almacén…","toast");wl.addWidget(self.toast)
        self.build_home();self.build_orders();self.build_work();self.build_trips();self.build_destinations()
        for table,key,caption,utc in [
            (self.overview,"fecha","Entrega solicitada",False),
            (self.calendar,"fecha","Día de preparación",False),
            (self.worklist,"fecha","Día programado",False),
            (self.units,"fecha_empaque","Fecha de empaque",True),
            (self.shipments,"apertura","Apertura del viaje",True),
            (self.loading,"fecha_empaque","Fecha de empaque",True),
            (self.destinations,"fecha_alta","Alta del destino",True)]:
            table.add_dates(table.parentWidget().layout(),key,caption,utc)
        self.nav.currentRowChanged.connect(self.navigate);self.nav.setCurrentRow(0)
        self.monitor=QTimer(self);self.monitor.setInterval(10000)
        self.monitor.timeout.connect(self.poll_supervisor);self.monitor.start()
        QTimer.singleShot(0,self.refresh)

    def poll_supervisor(self):
        # Read only, without locking the UI or opening repeated failure dialogs.
        if not self.isVisible() or self.jobs or QApplication.activeModalWidget():
            return
        job=Job(self.api.snapshot);self.jobs.add(job)
        def finished(value,error=False):
            self.jobs.discard(job)
            if error:
                self.supervisor.freshness.setText("SIN ACTUALIZAR · Últimos datos conservados. Revisa la conexión.")
                return
            self.render(value)
        job.signals.done.connect(lambda value:finished(value))
        job.signals.error.connect(lambda value:finished(value,True))
        self.pool.start(job)

    def page(self):
        body=QWidget();body.setObjectName("pageBody");v=QVBoxLayout(body);v.setContentsMargins(0,4,0,0);v.setSpacing(14)
        scroll=QScrollArea();scroll.setWidgetResizable(True);scroll.setWidget(body);self.pages.addWidget(scroll)
        return v

    def build_home(self):
        from frontend.desktop.supervisor_panel import SupervisorPanel
        v=self.page()
        self.supervisor=SupervisorPanel(self);v.addWidget(self.supervisor);v.addStretch()
        # Retain the existing suggested-action calculation for administrative actions.
        self.metrics={}
        self.next_heading=label("");self.next_description=label("")
        self.next_button=button("",self.next_action)

    def build_orders(self):
        v=self.page();row=QHBoxLayout()
        row.addWidget(button("Nuevo pedido de prueba",self.new_order,True))
        row.addWidget(button("Usar los 3 pedidos del ejemplo",self.import_sample))
        row.addWidget(button("Importar CSV o TXT…",self.csv_dialog));row.addStretch();v.addLayout(row)
        self.overview=DataTable([("descripcion","Producto"),("destino","Entregar en"),("cantidad","Piezas"),("pendiente","Por embarcar"),("fecha","Fecha solicitada")]);v.addWidget(self.overview,2)
        f,c=self.card();c.addWidget(label("¿Cuántas piezas puedes preparar al día?","section"))
        c.addWidget(label("La app reparte los pendientes de lunes a sábado. Puedes cambiar la sugerencia de 600 piezas por almacén.","muted"))
        row=QHBoxLayout();row.addWidget(label("Piezas por día"))
        self.capacity=QSpinBox();self.capacity.setRange(1,100000);self.capacity.setValue(600);row.addWidget(self.capacity)
        row.addWidget(label("Empezar el"))
        self.start=QDateEdit(QDate.currentDate())
        self.start.setCalendarPopup(True)
        self.start.setDisplayFormat("dd/MM/yyyy")
        self.start.setMinimumDate(QDate.currentDate())   # bloquea fechas pasadas
        row.addWidget(self.start)
        row.addStretch();self.plan_button=button("Organizar pedidos pendientes",self.plan,True);row.addWidget(self.plan_button)
        c.addLayout(row);c.addWidget(label("Los días ya programados conservan su capacidad. Las cantidades que no caben continúan en el siguiente día disponible.","muted"));v.addWidget(f)
        self.calendar=DataTable([("almacen","Almacén"),("fecha","Día de preparación"),("reservado","Piezas programadas"),("libre","Capacidad restante")]);v.addWidget(self.calendar,1)

    def build_work(self):
        v=self.page()
        v.addWidget(label("Elige una tarea. La cantidad pendiente y los datos del producto ya están completos.","muted"))
        self.worklist=DataTable([("descripcion","Producto"),("destino","Tienda"),("fecha","Día simulado"),("cantidad","Programado"),("por_recoger","Por recoger"),("por_empacar","Por empacar")])
        self.worklist.itemSelectionChanged.connect(self.update_work_buttons);v.addWidget(self.worklist,2)
        row=QHBoxLayout();self.pick_button=button("Recoger producto",self.pick,True)
        self.pack_button=button("Empacar recogido",self.pack)
        row.addWidget(self.pick_button);row.addWidget(self.pack_button);row.addStretch();v.addLayout(row)
        v.addWidget(label("Tarimas listas para pasar al área de salida","section"))
        self.units=DataTable([("descripcion","Producto"),("destino","Tienda"),("cantidad","Piezas"),("estado","Situación"),("fecha_empaque","Empacado el")]);v.addWidget(self.units,1)
        self.stage_button=button("Llevar tarima al área de salida",self.stage,True);v.addWidget(self.stage_button)
        self.units.itemSelectionChanged.connect(lambda:self.stage_button.setEnabled(bool(self.units.selected())))
        v.addWidget(label("Confirmación guiada de prueba: los códigos vienen completos. No equivale a un escaneo físico. El día de ejecución es el día simulado de la tarea.","muted"))

        v.addWidget(label("Historial de empaque · incluye tarimas ya embarcadas","section"))
        self.packing_history=DataTable([("codigo","Tarima"),("descripcion","Producto"),("cantidad","Piezas"),("fecha_empaque","Empacado el"),("estado","Situación")])
        v.addWidget(self.packing_history)
        self.packing_history.add_dates(v,"fecha_empaque","Registro real de empaque",True)

    def build_trips(self):
        v=self.page();row=QHBoxLayout()
        self.trip_button=button("Preparar nuevo viaje",self.create_trip,True);row.addWidget(self.trip_button)
        row.addWidget(button("Ver manifiesto",self.manifest));row.addStretch();v.addLayout(row)
        self.shipments=DataTable([("viaje","Viaje"),("apertura","Abierto el"),("estado","Situación"),("unidades","Tarimas"),("cargadas","Ya cargadas")])
        self.shipments.itemSelectionChanged.connect(self.update_route);v.addWidget(self.shipments,1)
        self.route=label("El viaje te mostrará dónde entregar primero.","route");v.addWidget(self.route)
        self.loading=DataTable([("descripcion","Producto"),("destino","Tienda"),("parada","Entrega número"),("cantidad","Piezas"),("estado","Situación"),("fecha_empaque","Empacado el")]);v.addWidget(self.loading,2)
        row=QHBoxLayout();self.load_button=button("Cargar siguiente tarima",self.load,True);row.addWidget(self.load_button)
        self.close_button=button("Cerrar embarque",self.close_trip);row.addWidget(self.close_button);v.addLayout(row)
        v.addWidget(label("Se carga primero lo que se entregará al final. Cerrar embarque registra la salida del almacén; no confirma la entrega en tienda.","muted"))

    def build_destinations(self):
        v=self.page();f,c=self.card()
        c.addWidget(label("Tus tiendas, a la distancia que tú indiques","section"))
        c.addWidget(label("Ejemplo: «Tienda del centro, a 5 km». La distancia siempre parte de este almacén. La app propone entregar de la más cercana a la más lejana.","muted"))
        row=QHBoxLayout();row.addWidget(button("Agregar destino",self.destination_form,True));row.addWidget(button("Editar destino seleccionado",lambda:self.destination_form(self.destinations.selected())));row.addStretch();c.addLayout(row);v.addWidget(f)
        self.destinations=DataTable([("nombre","Nombre del destino"),("km","Km desde el almacén"),("fecha_alta","Alta")]);v.addWidget(self.destinations,2)
        v.addWidget(label("Los 3 destinos iniciales y sus distancias son ficticios. Cambiarlos afecta propuestas futuras; los viajes creados conservan su orden y distancia registrados. No se calculan carreteras, tráfico ni kilómetros entre tiendas.","muted"));v.addStretch()

    def navigate(self,index):
        titles=["Tu almacén, de un vistazo","¿Qué vamos a surtir?","Prepara un producto a la vez","Cada tienda, en su orden","¿Dónde vas a entregar?"]
        subtitles=["Supervisión · trabajo programado, pendientes y confirmaciones","Elige productos y tiendas. Nosotros generamos el CSV de prueba.","Recoge, empaca y deja listo para cargar.","Revisa la propuesta antes de crear el viaje.","Solo necesitas el nombre del destino y sus kilómetros."]
        self.pages.setCurrentIndex(index);self.title.setText(titles[index]);self.subtitle.setText(subtitles[index])

    def render(self,state):
        self.state=state;total=state["totals"]
        self.supervisor.render(state.get("supervisor"))
        values=dict(total,pendiente=total["cantidad"]-total["embarcado"])
        for key,w in self.metrics.items():w.setText(number(values[key]))
        self.overview.populate([dict(r,pendiente=r["cantidad"]-r["embarcado"]) for r in state["lines"]])
        tasks=[dict(r,por_recoger=r["cantidad"]-r["recogido"],por_empacar=r["recogido"]-r["empacado"]) for r in state["tasks"] if r["empacado"]<r["cantidad"]]
        self.worklist.populate(tasks)
        self.calendar.populate([dict(r,libre=r["capacidad"]-r["reservado"]) for r in state["days"]])
        self.units.populate([r for r in state["units"] if r["estado"]=="PACKED"])
        self.packing_history.populate(state["units"])
        self.shipments.populate(state["shipments"]);self.destinations.populate(state.get("destinations",[]))
        self.plan_button.setEnabled(total["planeado"]<total["cantidad"])
        self.stage_button.setEnabled(bool(self.units.selected()));self.update_work_buttons();self.update_route()
        open_trip=next((r for r in state["shipments"] if r["estado"] in ("OPEN","LOADING")),None)
        staged=any(r["estado"]=="STAGED" and r["shipment_id"] is None for r in state["units"])
        self.trip_button.setEnabled(staged and open_trip is None)
        self.next_kind="new";self.next_target=1
        if not total["cantidad"]: heading="Crea tu primer pedido";desc="Elige Coca-Cola, Sabritas o Ruffles y la tienda que vas a surtir.";caption="Crear pedido de prueba"
        elif open_trip:
            self.next_target=3
            if open_trip["cargadas"]<open_trip["unidades"]:
                self.next_kind="load";heading="Continúa la carga del viaje";desc="Ya elegimos la siguiente tarima según el orden de entrega.";caption="Cargar siguiente tarima"
            else:self.next_kind="close";heading="Tu viaje está listo para salir";desc="Todas sus tarimas están cargadas. Confirma el sello para cerrar.";caption="Cerrar embarque"
        elif staged:
            self.next_kind="trip";self.next_target=3;heading="Prepara el siguiente viaje";desc="Revisa las tiendas y sus kilómetros antes de asignar la carga.";caption="Revisar propuesta de viaje"
        elif self.units.rowCount():
            self.next_kind="stage";self.next_target=2;heading="Lleva la tarima al área de salida";desc="El producto ya está empacado. Confirma que está listo para cargar.";caption="Enviar al área de salida"
        elif any(t["por_empacar"]>0 for t in tasks):
            self.next_kind="pack";self.next_target=2;heading="Empaca lo que ya recogiste";desc="La cantidad disponible viene seleccionada. Puedes empacar una parte.";caption="Empacar producto"
        elif tasks:
            self.next_kind="pick";self.next_target=2;heading="Recoge el siguiente producto";desc="Te mostramos qué producto, para qué tienda y cuántas piezas faltan.";caption="Recoger producto"
        elif total["planeado"]<total["cantidad"]:
            self.next_kind="plan";heading="Organiza los pedidos por día";desc="Revisa la capacidad sugerida de 600 piezas al día por almacén y la fecha inicial.";caption="Organizar pedidos"
        else:heading="¡Todo lo solicitado salió del almacén!";desc="Puedes crear otro pedido o consultar el historial de movimientos.";caption="Crear otro pedido"
        self.next_heading.setText(heading);self.next_description.setText(desc);self.next_button.setText(caption)
        self.toast.setText(self.toast.text() if not self.toast.text().startswith("Conectando") else "Conectado · Tus cambios se guardan en SQL Server.")

    def update_work_buttons(self):
        if not hasattr(self,"pick_button"):return
        row=self.worklist.selected()
        pick=int(row["por_recoger"]) if row else 0;pack=int(row["por_empacar"]) if row else 0
        self.pick_button.setEnabled(pick>0);self.pack_button.setEnabled(pack>0)
        self.pick_button.setText(f"Recoger {number(pick)} piezas" if pick else "Sin piezas por recoger")
        self.pack_button.setText(f"Empacar {number(pack)} piezas" if pack else "Primero recoge el producto")

    def selected(self,table):
        row=table.selected()
        if not row:QMessageBox.information(self,"Nada pendiente","No hay un registro disponible para esta acción.")
        return row

    def next_action(self):
        self.nav.setCurrentRow(self.next_target)
        if self.next_kind in ("pick","pack"):
            key="por_recoger" if self.next_kind=="pick" else "por_empacar"
            for i in range(self.worklist.rowCount()):
                if self.worklist.item(i,0).data(Qt.ItemDataRole.UserRole)[key]>0:self.worklist.selectRow(i);break
        if self.next_kind in ("load","close"):
            for i,r in enumerate(self.state["shipments"]):
                if r["estado"] in ("OPEN","LOADING"):self.shipments.selectRow(i);break
        actions={"new":self.new_order,"pick":self.pick,"pack":self.pack,"stage":self.stage,"trip":self.create_trip,"load":self.load,"close":self.close_trip}
        if self.next_kind in actions:actions[self.next_kind]()

    def _confirm(self,icon:str,title:str,lines:list[str]):
        """Show a non-blocking success dialog before the next refresh cycle."""
        dialog=QDialog(self)
        dialog.setWindowTitle("Operación completada")
        dialog.setMinimumWidth(420)
        layout=QVBoxLayout(dialog)
        layout.setSpacing(14)
        # Header row: big icon + title
        header=QHBoxLayout()
        icon_lbl=QLabel(icon)
        icon_lbl.setStyleSheet("font-size:36px;")
        icon_lbl.setFixedWidth(50)
        icon_lbl.setAlignment(Qt.AlignmentFlag.AlignTop)
        header.addWidget(icon_lbl)
        title_lbl=QLabel(title)
        title_lbl.setObjectName("section")
        title_lbl.setWordWrap(True)
        header.addWidget(title_lbl,1)
        layout.addLayout(header)
        # Detail lines
        for line in lines:
            lbl=QLabel(line)
            lbl.setObjectName("muted")
            lbl.setWordWrap(True)
            layout.addWidget(lbl)
        # Button
        btn=QPushButton("Continuar")
        btn.setObjectName("primary")
        btn.setMinimumHeight(40)
        btn.clicked.connect(dialog.accept)
        layout.addWidget(btn)
        dialog.exec()

    def pick(self):
        row=self.selected(self.worklist)
        if not row or row["por_recoger"]<=0:return
        data=self.form("Confirmar recogida",f"{row['descripcion']} → {row['destino']}\nEstante de surtido · {row['fecha']} (día simulado)\nLos códigos del producto y del estante están completos para esta prueba.",[("quantity","Piezas que recogiste",int(row["por_recoger"]))])
        if not data:return
        snap=dict(row)   # capture before table refreshes
        qty=data["quantity"]
        remaining=int(snap["por_recoger"])-qty
        def on_pick_done(_):
            self._confirm(
                "📦","Producto recogido",
                [f"Producto: {snap['descripcion']}",
                 f"Tienda: {snap['destino']}",
                 f"Piezas recogidas: {number(qty)}",
                 f"Pendientes en esta tarea: {number(max(0,remaining))}",
                 f"Día simulado: {snap['fecha']}"],
            )
        self.command("pick",on_success=on_pick_done,id=row["id"],location=row["ubicacion"],material=row["material"],**data)

    def pack(self):
        row=self.selected(self.worklist)
        if not row or row["por_empacar"]<=0:return
        data=self.form("Confirmar empaque",f"{row['descripcion']} → {row['destino']}\nCrearemos una tarima identificada automáticamente.",[("quantity","Piezas que empacaste",int(row["por_empacar"]))])
        if not data:return
        snap=dict(row)
        qty=data["quantity"]
        def on_pack_done(result):
            # result contains 'message' with the HU code e.g. "Tarima DEMO-HU-XXXX creada con N piezas."
            hu_msg=result.get("message","")
            self._confirm(
                "📫","Tarima creada",
                [f"Producto: {snap['descripcion']}",
                 f"Tienda: {snap['destino']}",
                 f"Piezas empacadas: {number(qty)}",
                 hu_msg],
            )
        self.command("pack",on_success=on_pack_done,id=row["id"],**data)

    def stage(self):
        row=self.selected(self.units)
        if row and self.form("Confirmar traslado",f"{number(row['cantidad'])} piezas de {row['descripcion']}\nPara {row['destino']}\nConfirma que la tarima está en el área de salida.",[]) is not None:
            snap=dict(row)
            def on_stage_done(_):
                self._confirm(
                    "🚚","Tarima en área de salida",
                    [f"Tarima: {snap['codigo']}",
                     f"Producto: {snap['descripcion']}",
                     f"Tienda: {snap['destino']}",
                     f"Piezas: {number(snap['cantidad'])}",
                     "Lista para asignarse al siguiente viaje."],
                )
            self.command("stage",on_success=on_stage_done,id=row["id"])

    def plan(self):
        self.command("plan",start_date=self.start.date().toString("yyyy-MM-dd"),capacity=self.capacity.value())

    def update_route(self):
        if not hasattr(self,"loading"):return
        row=self.shipments.selected();sid=row["id"] if row else None
        stops=[s for s in self.state.get("stops",[]) if s["shipment_id"]==sid]
        self.route.setText("\n".join(f"{s['secuencia']}. {s['destino']}  ·  {s['km']:g} km "+("desde almacén" if s.get("km_basis")=="warehouse" else "desde parada anterior (viaje previo)") for s in stops) if stops else "Prepara un viaje para revisar el orden de entrega.")
        units=sorted([u for u in self.state.get("units",[]) if u["shipment_id"]==sid and sid is not None],key=lambda u:-(u["parada"] or 0))
        self.loading.populate(units)
        pending=[u for u in units if u["estado"]=="STAGED"]
        self.next_load=pending[0] if pending else None
        if pending:
            for index in range(self.loading.rowCount()):
                if self.loading.item(index,0).data(Qt.ItemDataRole.UserRole)["id"]==pending[0]["id"]:
                    self.loading.selectRow(index);break
        self.load_button.setEnabled(bool(pending))
        self.load_button.setText("Cargar siguiente: "+pending[0]["destino"] if pending else "Sin tarimas por cargar")
        self.close_button.setEnabled(bool(row and row["estado"]=="LOADING" and row["cargadas"]==row["unidades"]))

    def create_trip(self):
        staged=[u for u in self.state.get("units",[]) if u["estado"]=="STAGED" and u["shipment_id"] is None]
        warehouses=sorted({u.get("almacen","Almacén") for u in staged})
        if len(warehouses)>1:
            from PySide6.QtWidgets import QInputDialog
            name,ok=QInputDialog.getItem(self,"Almacén de salida","Prepara un viaje de un solo almacén:",warehouses,0,False)
            if not ok:return
            staged=[u for u in staged if u.get("almacen","Almacén")==name]
        sites={u["DeliverySiteId"] for u in staged}
        catalog=self.state.get("destinations_by_warehouse",{}).get(str(staged[0].get("WarehouseId")),self.state.get("destinations",[])) if staged else []
        rows=[r for r in catalog if r["id"] in sites]
        if not rows or len(rows)!=len(sites) or any(r["km"] is None for r in rows):
            QMessageBox.information(self,"Faltan datos","Primero deja una tarima en el área de salida y registra los kilómetros de su destino.");return
        rows.sort(key=lambda r:(r["km"],r["nombre"].casefold(),r["id"]))
        text="PROPUESTA DE ENTREGA\n"+"\n".join(f"{i}. {r['nombre']} — {r['km']:g} km desde almacén" for i,r in enumerate(rows,1))
        text+=f"\n\n{len(staged)} tarimas. Se carga primero lo de la última tienda.\nEsta propuesta ordena por distancia; no calcula una ruta vial."
        if self.form("Crear este viaje",text,[]) is not None:
            self.command("create_trip",unit_ids=[u["id"] for u in staged],distance_ids=[r["distance_id"] for r in rows])

    def load(self):
        row=self.next_load
        if not row:return
        data=self.form("Confirmar carga",f"{row['descripcion']} · {number(row['cantidad'])} piezas\nPara {row['destino']} · entrega {row['parada']}\nTarima: {row['codigo']}\nConfirmación de prueba: el código ya está completo.",[])
        if data is None:return
        snap=dict(row)
        def on_load_done(_):
            self._confirm(
                "✅","Tarima cargada al tráiler",
                [f"Tarima: {snap['codigo']}",
                 f"Producto: {snap['descripcion']}",
                 f"Parada {snap['parada']}: {snap['destino']}",
                 f"Piezas: {number(snap['cantidad'])}"],
            )
        self.command("load",on_success=on_load_done,id=row["id"],code=row["codigo"])

    def close_trip(self):
        row=self.selected(self.shipments)
        if not row:return
        data=self.form("Cerrar embarque",f"{row['unidades']} tarimas · {row['cargadas']} cargadas\nViaje {row['viaje']}\nConfirmarás la salida del almacén.",[("seal","Sello del viaje","DEMO-SELLO-001")])
        if not data:return
        snap=dict(row)
        seal=data.get("seal","")
        def on_close_done(_):
            self._confirm(
                "🏁","Embarque cerrado",
                [f"Viaje: {snap['viaje']}",
                 f"Sello registrado: {seal}",
                 f"Tarimas despachadas: {snap['unidades']}",
                 "El manifiesto y la trazabilidad quedaron guardados.",
                 "Puedes ver el resumen completo en 'Ver manifiesto'."],
            )
        self.command("close",on_success=on_close_done,id=row["id"],**data)

    def dialog_buttons(self,dialog,layout,title):
        controls=QDialogButtonBox(QDialogButtonBox.StandardButton.Ok|QDialogButtonBox.StandardButton.Cancel)
        controls.button(QDialogButtonBox.StandardButton.Ok).setText(title)
        controls.button(QDialogButtonBox.StandardButton.Cancel).setText("Volver")
        controls.accepted.connect(dialog.accept);controls.rejected.connect(dialog.reject);layout.addWidget(controls)
        return controls

    def destination_form(self,row=None):
        if not isinstance(row,dict):row=None
        dialog=QDialog(self);dialog.setWindowTitle("Tu destino");dialog.setMinimumWidth(490)
        layout=QVBoxLayout(dialog);layout.addWidget(label("¿Dónde vas a entregar?","section"))
        layout.addWidget(label("Los kilómetros se cuentan desde tu almacén.","muted"))
        fields=QFormLayout();name=QLineEdit(row["nombre"] if row else "")
        name.setPlaceholderText("Ej. Tienda de la colonia Centro");name.setMaxLength(120)
        km=QDoubleSpinBox();km.setRange(.001,100000);km.setDecimals(3);km.setSuffix(" km")
        km.setValue(float(row["km"]) if row and row["km"] is not None else 5)
        fields.addRow("Nombre de la tienda",name);fields.addRow("Distancia desde almacén",km);layout.addLayout(fields)
        layout.addWidget(label("5 km es un ejemplo. Cambia la distancia a la que tú conoces.","muted"))
        controls=self.dialog_buttons(dialog,layout,"Guardar destino")
        ok=controls.button(QDialogButtonBox.StandardButton.Ok);ok.setEnabled(len(name.text().strip())>=2)
        name.textChanged.connect(lambda value:ok.setEnabled(len(value.strip())>=2))
        if dialog.exec()==QDialog.DialogCode.Accepted:
            payload=dict(name=name.text().strip(),km=km.value())
            if row:payload["id"]=row["id"]
            self.command("save_destination",**payload)

    def new_order(self):
        products=self.state.get("products",[]);destinations=self.state.get("destinations",[])
        if not products or not destinations:
            QMessageBox.information(self,"Conectando","Espera a que se carguen los productos y destinos.");return
        dialog=QDialog(self);dialog.setWindowTitle("Nuevo pedido de prueba");dialog.setMinimumWidth(520)
        layout=QVBoxLayout(dialog);layout.addWidget(label("Vamos a surtir una tienda","section"))
        layout.addWidget(label("Ya llenamos un ejemplo. Cambia solamente lo que necesites.","muted"))
        form=QFormLayout();product=QComboBox();destination=QComboBox()
        for r in products:product.addItem(r["nombre"],r["id"])
        for r in destinations:destination.addItem(r["nombre"],r["id"])
        qty=QSpinBox();qty.setRange(1,100000);qty.setValue(24);qty.setSuffix(" piezas")
        due=QDateEdit(QDate.currentDate().addDays(1))
        due.setCalendarPopup(True)
        due.setDisplayFormat("dd/MM/yyyy")
        due.setMinimumDate(QDate.currentDate())   # bloquea fechas pasadas
        for caption,widget in [("Producto",product),("Entregar en",destination),("Cantidad",qty),("Fecha solicitada",due)]:form.addRow(caption,widget)
        layout.addLayout(form);layout.addWidget(label("Generamos un CSV simulado y lo validamos antes de guardar el pedido. No necesitas escribir claves.","muted"))
        self.dialog_buttons(dialog,layout,"Crear pedido")
        if dialog.exec()==QDialog.DialogCode.Accepted:
            self.command("create_order",product_id=product.currentData(),destination_id=destination.currentData(),quantity=qty.value(),due_date=due.date().toString("yyyy-MM-dd"))

    def import_sample(self):
        def work():
            sample=self.api.sample()
            return self.api.command("import",**sample)
        def done(result):
            self.toast.setText(result.get("message","Ejemplo importado."));self.refresh()
        self.run(work,done)

    def csv_dialog(self):
        dialog=QDialog(self);dialog.setWindowTitle("Importar CSV o TXT");dialog.resize(850,570)
        layout=QVBoxLayout(dialog);layout.addWidget(label("Importar un archivo de prueba","section"))
        layout.addWidget(label("La demo admite CSV con comas o TXT con |, UTF-8 y 8 columnas con encabezado. Los productos y destinos deben estar registrados. El archivo real de SAP se adaptará después.","muted"))
        self.filename=label("Sin archivo seleccionado","eyebrow");layout.addWidget(self.filename)
        layout.addWidget(button("Seleccionar CSV o TXT…",self.open_csv))
        self.csv=QPlainTextEdit();self.csv.setPlaceholderText("Selecciona el archivo para ver su contenido.");layout.addWidget(self.csv)
        errors=self.state.get("errors",[])
        if errors:layout.addWidget(label("Últimos errores: "+"; ".join(r["mensaje"] for r in errors[:3]),"muted"))
        self.dialog_buttons(dialog,layout,"Validar e importar")
        if dialog.exec()==QDialog.DialogCode.Accepted and self.csv.toPlainText().strip():self.import_csv()

    def history(self):
        dialog=QDialog(self);dialog.setWindowTitle("Historial del almacén");dialog.resize(950,620)
        layout=QVBoxLayout(dialog);layout.addWidget(label("Lo que ha pasado en tu almacén","section"))
        import json
        names={"IMPORT":"Importar pedidos","CREATE_ORDER":"Crear pedido","SAVE_DESTINATION":"Guardar destino","PLAN":"Organizar pedidos","PICK":"Recoger producto","PACK":"Empacar producto","STAGE":"Mover al área de salida","CREATE_TRIP":"Crear viaje","LOAD":"Cargar tarima","CLOSE":"Cerrar embarque","INCIDENT":"Registrar incidencia"}
        rows=[]
        for r in self.state.get("audit",[]):
            try:detail=json.loads(r["detalle"]).get("message","")
            except (ValueError,TypeError):detail=""
            rows.append(dict(r,accion=names.get(r["accion"],r["accion"]),detalle=detail))
        table=DataTable([("fecha","Fecha"),("accion","Acción"),("detalle","Qué pasó")]);table.populate(rows);layout.addWidget(table);table.add_dates(layout,"fecha","Fecha de acción",True);table.populate(rows)
        layout.addWidget(button("Registrar incidencia",self.incident));layout.addWidget(button("Cerrar",dialog.accept));dialog.exec()
    def manifest(self):
        row=self.selected(self.shipments)
        if not row:return
        if row["estado"]!="CLOSED":
            QMessageBox.information(self,"Viaje en preparación","El resumen estará disponible cuando cierres el embarque.");return
        def show(result):
            from datetime import datetime
            dialog=QDialog(self);dialog.setWindowTitle("Resumen del embarque");dialog.resize(860,560)
            layout=QVBoxLayout(dialog);layout.addWidget(label("Esto salió de tu almacén","section"))
            layout.addWidget(label(f"Viaje {row['viaje']} · Sello {result['seal']}","muted"))
            units=result["units"];total=sum(u["cantidad"] for u in units)
            layout.addWidget(label(f"{number(total)} piezas · {len(units)} tarimas","metric"))
            table=DataTable([("descripcion","Producto"),("destino","Tienda"),("parada","Entrega"),("cantidad","Piezas")])
            sorted_units=sorted(units,key=lambda u:u["parada"]);table.populate(sorted_units);layout.addWidget(table)
            layout.addWidget(label("La salida está registrada. La entrega al cliente no se confirma desde esta demo.","muted"))

            def copy_to_clipboard():
                sep="─"*46
                lines=[
                    f"EMBARQUE  {row['viaje']}",
                    f"Sello:    {result['seal']}",
                    f"Piezas:   {number(total)}   |   Tarimas: {len(units)}",
                    sep,
                ]
                for u in sorted_units:
                    lines.append(f"{u['parada']:>2}. {u['destino']:<22} {u['descripcion']:<20} {number(u['cantidad']):>8} pzas")
                lines+=[sep,f"Generado: {datetime.now().strftime('%d/%m/%Y %H:%M')}"]
                text="\n".join(lines)
                QApplication.clipboard().setText(text)
                self.toast.setText("✓ Resumen copiado al portapapeles · Ya puedes pegarlo en WhatsApp, correo o Excel.")

            btn_row=QHBoxLayout()
            btn_row.addWidget(button("Copiar resumen",copy_to_clipboard,True))
            btn_row.addStretch()
            btn_row.addWidget(button("Cerrar",dialog.accept))
            layout.addLayout(btn_row)
            dialog.exec()
        self.run(lambda:self.api.request("GET",f"/demo/shipments/{row['id']}/manifest"),show)

