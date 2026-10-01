STYLE = """
QWidget {font-family: 'Segoe UI'; font-size: 13px; color: #25354A;}
QMainWindow, #workspace, #pageBody {background: #F3F6FA;}
QFrame#sidebar {background: #111F32; border: none;}
QLabel#brand {font-size: 24px; font-weight: 750; color: white;}
QLabel#brandSub {color: #89A0BA; font-size: 11px;}
QLabel#navFooter {color: #95A9C0; font-size: 12px;}
QListWidget#nav {background: transparent; color: #AFC0D3; border: none; outline: none; font-size: 14px;}
QListWidget#nav::item {padding: 15px 14px; margin: 3px 0px; border-radius: 8px;}
QListWidget#nav::item:selected {background: #243B51; color: #65E1CB; font-weight: bold;}
QListWidget#nav::item:hover {background: #1C3046;}
QLabel#eyebrow {color: #008875; font-weight: bold; font-size: 11px;}
QLabel#title {font-size: 30px; font-weight: 700; color: #15263B;}
QLabel#subtitle {color: #667A91; font-size: 13px;}
QLabel#badge {background: #FFF0D4; color: #8D5B0C; border-radius: 6px; padding: 7px 11px; font-weight: bold; font-size: 11px;}
QLabel#toast {background: #E0F3EC; color: #166B54; padding: 12px; border-radius: 7px;}
QFrame#card {background: white; border: 1px solid #E1E7EF; border-radius: 11px;}
QLabel#cardLabel {color: #667A91; font-size: 12px;}
QLabel#metric {font-size: 32px; font-weight: 750; color: #19334C;}
QLabel#section {font-size: 17px; font-weight: 650; color: #23374E;}
QLabel#muted {color: #718398;}
QPushButton {background: white; color: #294057; border: 1px solid #D8E2ED; border-radius: 7px; padding: 10px 15px; font-weight: 600;}
QPushButton:hover {background: #EAF0F7;}
QPushButton:disabled {color: #A7B4C3; background: #EEF2F6; border-color: #E5EBF1;}
QPushButton#primary {background: #008B79; color: white; border: none;}
QPushButton#primary:hover {background: #007768;}
QPushButton#primary:disabled {background: #B5D5CE;}
QTableWidget {background: white; alternate-background-color: #F8FAFC; border: 1px solid #E1E7EF; border-radius: 8px; gridline-color: #EDF1F5; selection-background-color: #DFF3EF; selection-color: #155E51;}
QTableWidget::item {padding: 8px; border: none;}
QHeaderView::section {background: #EAF0F6; color: #63758B; padding: 10px; border: none; font-weight: 600; font-size: 12px;}
QPlainTextEdit, QTextEdit, QLineEdit, QSpinBox, QDoubleSpinBox, QComboBox, QDateEdit {background: white; border: 1px solid #D7E1EB; border-radius: 6px; padding: 9px; selection-background-color: #B4E4D9;}
QProgressBar {background: #E9EFF4; border: none; border-radius: 5px; height: 10px; text-align: center; color: #31495E;}
QProgressBar::chunk {background: #00A38B; border-radius: 5px;}
QScrollArea {background: transparent; border: none;}
QFrame#hero {background: #E1F3EE; border: 1px solid #B5DED2; border-radius: 12px;}
QLabel#step {background: #E9EEF5; padding: 14px 10px; border-radius: 7px; font-weight: 600;}
QLabel#route {background: #E1F3EE; padding: 16px; border-radius: 8px; font-size: 14px;}
QDialog {background: #F5F8FB;}
QLabel#stageLabel {font-size: 13px; font-weight: 600; color: #3A4F65;}
QLabel#stageCounter {font-size: 12px; color: #7A8FA5;}
QLabel#stagePct {font-size: 12px;}

/* Estilos para el calendario emergente */
QCalendarWidget QWidget {
    alternate-background-color: #FAFCFF;
}
QCalendarWidget QToolButton {
    color: #19334C;
    font-size: 14px;
    font-weight: 600;
    icon-size: 20px;
    background-color: transparent;
    padding: 4px;
}
QCalendarWidget QToolButton:hover {
    background-color: #EAF0F7;
    border-radius: 4px;
}
QCalendarWidget QMenu {
    width: 150px;
    left: 20px;
    color: white;
    font-size: 14px;
    background-color: #243B51;
}
QCalendarWidget QSpinBox {
    width: 60px;
    font-size: 14px;
    color: #19334C;
    background-color: transparent;
    selection-background-color: #B4E4D9;
}
QCalendarWidget QSpinBox::up-button, QCalendarWidget QSpinBox::down-button {
    subcontrol-origin: border;
}
QCalendarWidget QSpinBox::up-arrow, QCalendarWidget QSpinBox::down-arrow {
    width: 10px;
    height: 10px;
}
QCalendarWidget QWidget#qt_calendar_navigationbar {
    background-color: white;
    border-bottom: 1px solid #E1E7EF;
}
QCalendarWidget QAbstractItemView:enabled {
    font-size: 13px;
    color: #25354A;
    background-color: white;
    selection-background-color: #008B79;
    selection-color: white;
}
QCalendarWidget QAbstractItemView:disabled {
    color: #C0CDDB; /* Días no disponibles (fechas pasadas bloqueadas) */
}
"""
