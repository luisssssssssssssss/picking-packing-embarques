"""Explicit selection of available staged units for one outbound trip."""
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QDialog,QVBoxLayout,QHBoxLayout,QComboBox,QLabel,QTableWidget,QTableWidgetItem,QHeaderView,QPushButton,QAbstractItemView

class TripSelectionDialog(QDialog):
    def __init__(self,state,parent=None):
        super().__init__(parent)
        self.setWindowTitle("Crear viaje · elige qué enviar")
        self.resize(960,600)
        self.state=state
        self.available=[u for u in state.get("units",[]) if u["estado"]=="STAGED" and u["shipment_id"] is None]
        self.payload=None
        layout=QVBoxLayout(self)
        layout.addWidget(QLabel("Selecciona las tarimas que saldrán en este viaje. Las demás siguen disponibles."))
        self.warehouse=QComboBox()
        warehouses={u["WarehouseId"]:u["almacen"] for u in self.available}
        for ident,name in sorted(warehouses.items(),key=lambda r:r[1]):
            self.warehouse.addItem(name,ident)
        layout.addWidget(self.warehouse)
        actions=QHBoxLayout()
        for text,checked in (("Seleccionar todas",True),("Quitar selección",False)):
            button=QPushButton(text);button.clicked.connect(lambda _,value=checked:self.select_all(value));actions.addWidget(button)
        actions.addStretch();layout.addLayout(actions)
        self.table=QTableWidget(0,6)
        self.table.setHorizontalHeaderLabels(["Enviar","ID pedido","Producto","Piezas","Destino","Tarima"])
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().hide()
        self.table.setAlternatingRowColors(True)
        layout.addWidget(self.table,1)
        self.summary=QLabel();self.summary.setWordWrap(True);layout.addWidget(self.summary)
        self.route=QLabel();self.route.setWordWrap(True);layout.addWidget(self.route)
        layout.addWidget(QLabel("Un viaje sale de un solo almacén. Se carga primero lo que se entrega al final."))
        buttons=QHBoxLayout()
        cancel=QPushButton("Volver");cancel.clicked.connect(self.reject)
        self.confirm=QPushButton("Crear viaje con la selección")
        self.confirm.clicked.connect(self.accept_selection)
        buttons.addWidget(cancel);buttons.addWidget(self.confirm);layout.addLayout(buttons)
        self.table.itemChanged.connect(self.update_selection)
        self.warehouse.currentIndexChanged.connect(self.fill)
        self.fill()

    def fill(self):
        self.rows=[u for u in self.available if u["WarehouseId"]==self.warehouse.currentData()]
        self.table.blockSignals(True);self.table.setRowCount(len(self.rows))
        for index,row in enumerate(self.rows):
            check=QTableWidgetItem()
            check.setFlags(Qt.ItemFlag.ItemIsEnabled|Qt.ItemFlag.ItemIsUserCheckable)
            check.setCheckState(Qt.CheckState.Unchecked);self.table.setItem(index,0,check)
            for col,key in enumerate(("id_pedido","descripcion","cantidad","destino","codigo"),1):
                item=QTableWidgetItem(str(row.get(key,row.get("pedido","") if key=="id_pedido" else "")))
                item.setToolTip(item.text());self.table.setItem(index,col,item)
        self.table.blockSignals(False);self.update_selection()

    def select_all(self,checked):
        self.table.blockSignals(True)
        for i in range(self.table.rowCount()):
            self.table.item(i,0).setCheckState(Qt.CheckState.Checked if checked else Qt.CheckState.Unchecked)
        self.table.blockSignals(False);self.update_selection()

    def update_selection(self,*_):
        selected=[u for i,u in enumerate(self.rows) if self.table.item(i,0).checkState()==Qt.CheckState.Checked]
        self.payload=None;self.confirm.setEnabled(False)
        self.summary.setText(f"{len(selected)} tarimas · {sum(u['cantidad'] for u in selected):g} piezas seleccionadas")
        if not selected:
            self.route.setText("Marca al menos una tarima para ver el orden de entrega.");return
        sites={u["DeliverySiteId"] for u in selected}
        catalog=self.state.get("destinations_by_warehouse",{}).get(str(self.warehouse.currentData()),self.state.get("destinations",[]))
        route=sorted([r for r in catalog if r["id"] in sites],key=lambda r:(r["km"] is None,r["km"] or 0,r["nombre"].casefold(),r["id"]))
        if len(route)!=len(sites) or any(r["km"] is None for r in route):
            self.route.setText("Faltan kilómetros para un destino seleccionado. Revisa sus datos antes de crear el viaje.");return
        self.route.setText("Orden de entrega:\n"+"\n".join(f"{i}. {r['nombre']} · {r['km']:g} km desde el almacén" for i,r in enumerate(route,1)))
        self.payload=dict(unit_ids=[u["id"] for u in selected],distance_ids=[r["distance_id"] for r in route])
        self.confirm.setEnabled(True)

    def accept_selection(self):
        self.update_selection()
        if self.payload:self.accept()
