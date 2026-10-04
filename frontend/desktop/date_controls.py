"""Date controls for read-only tables; ISO dates sort chronologically."""
from datetime import datetime, timedelta, timezone
from PySide6.QtCore import QDate
from PySide6.QtWidgets import QWidget,QHBoxLayout,QComboBox,QCheckBox,QDateEdit,QPushButton,QLabel

LOCAL_ZONE=timezone(timedelta(hours=-6))

def local_stamp(value):
    if not value:return ""
    stamp=datetime.fromisoformat(str(value).replace("Z","+00:00"))
    if stamp.tzinfo is None:stamp=stamp.replace(tzinfo=timezone.utc)
    return stamp.astimezone(LOCAL_ZONE).isoformat()

class DateControls(QWidget):
    def __init__(self,table,key,caption,utc=False):
        super().__init__()
        self.table=table;self.key=key;self.utc=utc
        row=QHBoxLayout(self);row.setContentsMargins(0,0,0,0)
        title=QLabel(caption+(" · CDMX" if utc else ""));title.setWordWrap(True);title.setMaximumWidth(210);row.addWidget(title)
        self.order=QComboBox();self.order.addItems(["Más recientes primero","Más antiguas primero"]);row.addWidget(self.order)
        self.exact=QCheckBox("Fecha exacta");row.addWidget(self.exact)
        self.date=QDateEdit(QDate.currentDate());self.date.setCalendarPopup(True);self.date.setDisplayFormat("dd/MM/yyyy");self.date.setEnabled(False);row.addWidget(self.date)
        clear=QPushButton("Todas las fechas");row.addWidget(clear)
        self.count=QLabel("");row.addWidget(self.count);row.addStretch()
        self.order.currentIndexChanged.connect(self.refresh)
        self.date.dateChanged.connect(self.refresh)
        self.exact.toggled.connect(self.date.setEnabled);self.exact.toggled.connect(self.refresh)
        clear.clicked.connect(lambda:self.exact.setChecked(False))
    def refresh(self,*args):
        self.table.populate(self.table.source_rows)
    def apply(self,rows):
        def stamp(row):
            value=row.get(self.key)
            return local_stamp(value) if self.utc else str(value or "")
        result=[dict(r) for r in rows if not self.exact.isChecked() or stamp(r)[:10]==self.date.date().toString("yyyy-MM-dd")]
        present=[r for r in result if stamp(r)]
        missing=[r for r in result if not stamp(r)]
        present.sort(key=stamp,reverse=self.order.currentIndex()==0)
        result=present+missing
        if self.utc:
            for r in result:r[self.key]=stamp(r)
        self.count.setText(f"{len(result)} registros")
        return result
