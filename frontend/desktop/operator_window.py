"""Operator (montacarguista) window — Validación Rápida flow.

State machine
─────────────
S_IDLE   ── no task / loading / paused after incident
S_TASK   ── task info visible; operator picks an action
S_SCAN   ── camera / code verification panel   (pick only)
S_CHECK  ── 2-digit fallback keypad
S_OK     ── location verified; 1-touch confirm button
S_SHORT  ── faltante: numeric keypad for partial quantity

Desktop note: scanning is simulated with a text field. On Android the same
flow would use the device camera with ML Kit / ZXing instead.
"""
from uuid import uuid4

from PySide6.QtCore import Qt, QTimer, QThreadPool
from PySide6.QtWidgets import (
    QComboBox, QDialog, QDialogButtonBox, QFrame, QGridLayout,
    QHBoxLayout, QLabel, QLineEdit, QMainWindow, QPlainTextEdit,
    QProgressBar, QPushButton, QScrollArea, QStackedWidget,
    QVBoxLayout, QWidget,
)

from frontend.desktop.client import Api
from frontend.desktop.theme import STYLE
from frontend.desktop.widgets import Job, button, label, number

# ── Dark high-contrast theme — readable at 1 m, glove-friendly buttons ────
OPERATOR_STYLE = """
QMainWindow { background: #0F1F2E; }
QWidget#opShell { background: #0F1F2E; }
QScrollArea { background: transparent; border: none; }
QScrollArea > QWidget > QWidget { background: transparent; }

/* ── Cards ─────────────────────────────────────────── */
QFrame#locationCard {
    background: #0B2E20; border-radius: 14px; border: 2px solid #007C69;
}
QFrame#taskCard {
    background: #17304A; border-radius: 14px; border: 1px solid #253E57;
}
QFrame#scanFrame {
    background: #0A1D2C; border-radius: 12px;
    border: 2px dashed #2A5A8A; min-height: 150px;
}
QFrame#keypadFrame { background: #0A1D2C; border-radius: 14px; }
QFrame#validatedFrame {
    background: #0B2E20; border-radius: 16px; border: 2px solid #00875A;
}
QFrame#faltanteFrame {
    background: #2E1A0A; border-radius: 16px; border: 2px solid #C87820;
}

/* ── Top bar ────────────────────────────────────────── */
QLabel#topTitle {
    font-size: 11px; color: #3A5A7A; font-weight: 700; letter-spacing: 3px;
}
QPushButton#topBtn {
    background: transparent; color: #5A8FAA;
    border: 1px solid #253E57; border-radius: 6px;
    font-size: 12px; padding: 5px 10px;
}
QPushButton#topBtn:hover { background: #17304A; }

/* ── Status / hints ────────────────────────────────── */
QLabel#statusText  { font-size: 13px; color: #4A6A8A; padding: 2px 0; }
QLabel#checkHint   { font-size: 13px; color: #3A6A8A; qproperty-alignment: AlignCenter; }
QProgressBar { background: #17304A; border: none; border-radius: 2px; max-height: 3px; }
QProgressBar::chunk { background: #007C69; border-radius: 2px; }

/* ── Step strip ─────────────────────────────────────── */
QLabel#stepLabel {
    font-size: 12px; color: #2E4A62; padding: 5px 4px;
    qproperty-alignment: AlignCenter;
}
QLabel#stepActive {
    font-size: 12px; color: #00D4A8; font-weight: 700; padding: 5px 4px;
    qproperty-alignment: AlignCenter;
}

/* ── Location / task labels ─────────────────────────── */
QLabel#locLabel   { font-size: 11px; color: #2E5A4A; font-weight: 700; letter-spacing: 2px; }
QLabel#locationCode { font-size: 42px; font-weight: 900; color: #00FF88; letter-spacing: 3px; }
QLabel#locationDest { font-size: 16px; font-weight: 700; color: #A0C8C0; }
QLabel#taskInstruction { font-size: 13px; color: #3A6A8A; font-weight: 700; letter-spacing: 2px; }
QLabel#taskProduct { font-size: 28px; font-weight: 800; color: #FFFFFF; }
QLabel#taskQty    { font-size: 52px; font-weight: 900; color: #00D4A8; }
QLabel#taskQtyUnit { font-size: 14px; color: #3A6A8A; margin-top: 34px; }
QLabel#taskStore  { font-size: 16px; color: #8AAABB; }

/* ── Primary scan / confirm button ──────────────────── */
QPushButton#btnMain {
    background: #007C69; color: #FFFFFF; border: none;
    border-radius: 14px; font-size: 19px; font-weight: 800;
    padding: 17px 20px;
}
QPushButton#btnMain:hover { background: #009A82; }
QPushButton#btnMain:disabled { background: #173A30; color: #2A6A5A; }

/* ── Secondary / fallback button ────────────────────── */
QPushButton#btnSecondary {
    background: #17304A; color: #8AAABB;
    border: 1px solid #253E57; border-radius: 10px;
    font-size: 15px; padding: 12px 16px;
}
QPushButton#btnSecondary:hover { background: #1E3A57; }

/* ── Exception buttons ──────────────────────────────── */
QPushButton#btnFaltante {
    background: transparent; color: #C87820;
    border: 1px solid #C87820; border-radius: 8px;
    font-size: 14px; padding: 10px 14px;
}
QPushButton#btnFaltante:hover { background: #2E1A0A; }
QPushButton#btnIncident {
    background: transparent; color: #C04040;
    border: 1px solid #C04040; border-radius: 8px;
    font-size: 14px; padding: 10px 14px;
}
QPushButton#btnIncident:hover { background: #2E1010; }

/* ── Scan panel ─────────────────────────────────────── */
QLabel#scanCamIcon { font-size: 44px; qproperty-alignment: AlignCenter; }
QLabel#scanHint    {
    font-size: 13px; color: #007C69; font-weight: 600;
    qproperty-alignment: AlignCenter;
}
QLineEdit#scanInput {
    background: #0A1D2C; color: #00FF88;
    border: 1px solid #2A5A8A; border-radius: 8px;
    font-size: 17px; padding: 10px 14px; font-family: monospace;
}

/* ── 2-digit check display ──────────────────────────── */
QLabel#checkDisplay {
    font-size: 58px; font-weight: 900; color: #00FF88;
    background: #0A1D2C; border-radius: 10px;
    padding: 10px 28px; qproperty-alignment: AlignCenter;
    letter-spacing: 10px; min-width: 160px;
}

/* ── Keypad buttons ─────────────────────────────────── */
QPushButton#keyBtn {
    background: #17304A; color: #FFFFFF;
    border: 1px solid #253E57; border-radius: 12px;
    font-size: 26px; font-weight: 800;
    min-height: 65px; min-width: 72px;
}
QPushButton#keyBtn:hover   { background: #1E3A57; }
QPushButton#keyBtn:pressed { background: #007C69; border-color: #007C69; }
QPushButton#keyDel {
    background: #2E1A0A; color: #C87820;
    border: 1px solid #5A3A1A; border-radius: 12px;
    font-size: 20px; min-height: 65px; min-width: 72px;
}
QPushButton#keyDel:hover   { background: #3E2A0A; }
QPushButton#keyDel:pressed { background: #5E3A0A; }
QPushButton#keyValidate {
    background: #007C69; color: white; border: none;
    border-radius: 12px; font-size: 17px; font-weight: 700; min-height: 60px;
}
QPushButton#keyValidate:hover { background: #009A82; }
QPushButton#keyValidate:disabled { background: #173A30; color: #2A6A5A; }

/* ── Validated panel ────────────────────────────────── */
QLabel#validatedIcon { font-size: 66px; qproperty-alignment: AlignCenter; }
QLabel#validatedText {
    font-size: 20px; font-weight: 800; color: #00FF88;
    qproperty-alignment: AlignCenter;
}
QPushButton#btnConfirm {
    background: #007C69; color: white; border: none;
    border-radius: 16px; font-size: 21px; font-weight: 900; padding: 20px;
}
QPushButton#btnConfirm:hover { background: #009A82; }
QPushButton#btnConfirm:disabled { background: #173A30; color: #2A6A5A; }

/* ── Faltante panel ─────────────────────────────────── */
QLabel#faltanteTitle {
    font-size: 15px; color: #C87820; font-weight: 700;
    qproperty-alignment: AlignCenter;
}
QLabel#faltanteQty {
    font-size: 52px; font-weight: 900; color: #E8A234;
    qproperty-alignment: AlignCenter;
}
QPushButton#faltanteConfirm {
    background: #C87820; color: #0F1F2E; border: none;
    border-radius: 12px; font-size: 17px; font-weight: 800; padding: 15px;
}
QPushButton#faltanteConfirm:hover { background: #E8A234; }
QPushButton#faltanteConfirm:disabled { background: #3A2A0A; color: #6A4A10; }

/* ── Idle panel ─────────────────────────────────────── */
QLabel#idleMsg { font-size: 16px; color: #8AAABB; qproperty-alignment: AlignCenter; }
"""


class OperatorWindow(QMainWindow):
    """Single-task operator view with Validación Rápida state machine."""

    S_IDLE, S_TASK, S_SCAN, S_CHECK, S_OK, S_SHORT = range(6)

    def __init__(self, api=None):
        super().__init__()
        self.api = api or Api()
        self.state: dict = {}
        self.task: dict | None = None
        self.preferred: int | None = None
        self.pending: dict | None = None
        self.jobs: set = set()
        self.pool = QThreadPool(self)
        self.admin = None
        self.paused = False
        self._check_buf = ""           # digits entered in check-digit keypad
        self._short_str = "0"          # digits entered in faltante keypad
        self._short_from = self.S_TASK # panel to return to on SHORT cancel

        self.setWindowTitle("Mi almacén | Montacarguista")
        self.resize(480, 860)
        self.setMinimumSize(360, 640)
        self.setStyleSheet(STYLE + OPERATOR_STYLE)

        shell = QWidget()
        shell.setObjectName("opShell")
        self.setCentralWidget(shell)
        root = QVBoxLayout(shell)
        root.setContentsMargins(14, 10, 14, 10)
        root.setSpacing(6)

        # ── Top bar ────────────────────────────────────────────
        top = QHBoxLayout()
        lbl_title = QLabel("MI TAREA")
        lbl_title.setObjectName("topTitle")
        top.addWidget(lbl_title)
        top.addStretch()
        self.btn_refresh = QPushButton("Actualizar")
        self.btn_refresh.setObjectName("topBtn")
        self.btn_refresh.setToolTip("Actualizar")
        self.btn_refresh.clicked.connect(self._idle_action)
        top.addWidget(self.btn_refresh)
        self.btn_admin = QPushButton("Supervisor")
        self.btn_admin.setObjectName("topBtn")
        self.btn_admin.clicked.connect(self.open_admin)
        top.addWidget(self.btn_admin)
        root.addLayout(top)

        self.status_lbl = QLabel("Buscando tu siguiente tarea…")
        self.status_lbl.setObjectName("statusText")
        self.status_lbl.setWordWrap(True)
        root.addWidget(self.status_lbl)

        self.progress = QProgressBar()
        self.progress.setRange(0, 0)
        self.progress.hide()
        root.addWidget(self.progress)

        # ── Step strip ─────────────────────────────────────────
        strip = QHBoxLayout()
        strip.setSpacing(0)
        self.step_labels: list[QLabel] = []
        for txt in ("1 Recoger", "2 Empacar", "3 Llevar", "4 Cargar"):
            lbl_s = QLabel(txt)
            lbl_s.setObjectName("stepLabel")
            strip.addWidget(lbl_s, 1)
            self.step_labels.append(lbl_s)
        root.addLayout(strip)

        # ── State panels ───────────────────────────────────────
        self.panels = QStackedWidget()
        root.addWidget(self.panels, 1)

        self._build_idle_panel()     # index 0
        self._build_task_panel()     # index 1
        self._build_scan_panel()     # index 2
        self._build_check_panel()    # index 3
        self._build_ok_panel()       # index 4
        self._build_short_panel()    # index 5

        self.hint_lbl = QLabel("Confirma cada paso solo después de realizarlo.")
        self.hint_lbl.setObjectName("statusText")
        self.hint_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        root.addWidget(self.hint_lbl)

        QTimer.singleShot(0, self.refresh)

    # ── Panel builders ─────────────────────────────────────────────────────

    def _build_idle_panel(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.addStretch()

        self.idle_msg = QLabel("")
        self.idle_msg.setObjectName("idleMsg")
        self.idle_msg.setWordWrap(True)
        v.addWidget(self.idle_msg)
        v.addSpacing(16)
        self.idle_btn = QPushButton("Buscar siguiente tarea")
        self.idle_btn.setObjectName("btnMain")
        self.idle_btn.clicked.connect(self._idle_action)
        v.addWidget(self.idle_btn)
        v.addStretch()
        self.panels.addWidget(w)

    def _build_task_panel(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        body = QWidget()
        v = QVBoxLayout(body)
        v.setContentsMargins(0, 4, 0, 4)
        v.setSpacing(10)

        # Location card
        loc = QFrame()
        loc.setObjectName("locationCard")
        lc = QVBoxLayout(loc)
        lc.setContentsMargins(18, 14, 18, 14)
        lc.setSpacing(4)
        self.loc_from_lbl = QLabel("RECOGE EN")
        self.loc_from_lbl.setObjectName("locLabel")
        lc.addWidget(self.loc_from_lbl)
        self.loc_code = QLabel("—")
        self.loc_code.setObjectName("locationCode")
        lc.addWidget(self.loc_code)
        self.loc_to_lbl = QLabel("LLEVA A")
        self.loc_to_lbl.setObjectName("locLabel")
        self.loc_to_lbl.setContentsMargins(0, 8, 0, 0)
        lc.addWidget(self.loc_to_lbl)
        self.loc_dest = QLabel("—")
        self.loc_dest.setObjectName("locationDest")
        self.loc_dest.setWordWrap(True)
        lc.addWidget(self.loc_dest)
        v.addWidget(loc)

        # Task info card
        tc_frame = QFrame()
        tc_frame.setObjectName("taskCard")
        tc = QVBoxLayout(tc_frame)
        tc.setContentsMargins(18, 14, 18, 14)
        tc.setSpacing(6)
        self.task_instr = QLabel("")
        self.task_instr.setObjectName("taskInstruction")
        tc.addWidget(self.task_instr)
        self.task_product = QLabel("")
        self.task_product.setObjectName("taskProduct")
        self.task_product.setWordWrap(True)
        tc.addWidget(self.task_product)
        qty_row = QHBoxLayout()
        self.task_qty = QLabel("0")
        self.task_qty.setObjectName("taskQty")
        qty_row.addWidget(self.task_qty)
        lbl_pzas = QLabel("piezas")
        lbl_pzas.setObjectName("taskQtyUnit")
        lbl_pzas.setAlignment(Qt.AlignmentFlag.AlignBottom | Qt.AlignmentFlag.AlignLeft)
        qty_row.addWidget(lbl_pzas)
        qty_row.addStretch()
        tc.addLayout(qty_row)
        self.task_store = QLabel("")
        self.task_store.setObjectName("taskStore")
        tc.addWidget(self.task_store)
        self.task_ref = QLabel("")
        self.task_ref.setObjectName("checkHint")
        tc.addWidget(self.task_ref)
        v.addWidget(tc_frame)

        # Primary action (scan or direct confirm)
        self.btn_primary = QPushButton("Escanear Ubicacion")
        self.btn_primary.setObjectName("btnMain")
        self.btn_primary.clicked.connect(self._primary_action)
        v.addWidget(self.btn_primary)

        # Fallback: check-digit (pick only)
        self.btn_use_check = QPushButton("Ingresar Digito de Control")
        self.btn_use_check.setObjectName("btnSecondary")
        self.btn_use_check.clicked.connect(self._go_check)
        v.addWidget(self.btn_use_check)

        # Exception row
        exc = QHBoxLayout()
        exc.setSpacing(8)
        self.btn_faltante_t = QPushButton("Reportar Faltante")
        self.btn_faltante_t.setObjectName("btnFaltante")
        self.btn_faltante_t.clicked.connect(lambda: self._go_short(from_ok=False))
        exc.addWidget(self.btn_faltante_t)
        self.btn_incident_t = QPushButton("Registrar Incidencia")
        self.btn_incident_t.setObjectName("btnIncident")
        self.btn_incident_t.clicked.connect(self.report_problem)
        exc.addWidget(self.btn_incident_t)
        v.addLayout(exc)

        v.addStretch()
        scroll.setWidget(body)
        self.panels.addWidget(scroll)

    def _build_scan_panel(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.setContentsMargins(0, 6, 0, 6)
        v.setSpacing(10)

        self.scan_heading = QLabel("Apunta la cámara al código de la ubicación")
        self.scan_heading.setObjectName("taskInstruction")
        self.scan_heading.setAlignment(Qt.AlignmentFlag.AlignCenter)
        v.addWidget(self.scan_heading)

        # Camera simulation frame
        cam = QFrame()
        cam.setObjectName("scanFrame")
        cv = QVBoxLayout(cam)
        cv.setContentsMargins(16, 14, 16, 14)
        cv.setSpacing(6)
        cam_ico = QLabel("Camara activa")
        cam_ico.setObjectName("scanCamIcon")
        cv.addWidget(cam_ico)
        cam_note = QLabel("Simulación de escritorio · Android usaría ML Kit / ZXing")
        cam_note.setObjectName("checkHint")
        cam_note.setWordWrap(True)
        cv.addWidget(cam_note)
        self.scan_expected_lbl = QLabel("")
        self.scan_expected_lbl.setObjectName("scanHint")
        cv.addWidget(self.scan_expected_lbl)
        v.addWidget(cam)

        lbl_scan = QLabel("CÓDIGO ESCANEADO:")
        lbl_scan.setObjectName("locLabel")
        v.addWidget(lbl_scan)
        self.scan_input = QLineEdit()
        self.scan_input.setObjectName("scanInput")
        self.scan_input.setPlaceholderText("Pega o escribe el código del rack…")
        self.scan_input.returnPressed.connect(self._try_scan)
        v.addWidget(self.scan_input)

        btn_val = QPushButton("Validar codigo escaneado")
        btn_val.setObjectName("btnMain")
        btn_val.clicked.connect(self._try_scan)
        v.addWidget(btn_val)

        sep = QLabel("── o ──")
        sep.setObjectName("checkHint")
        sep.setAlignment(Qt.AlignmentFlag.AlignCenter)
        v.addWidget(sep)

        btn_cd = QPushButton("Usar Digito de Control como respaldo")
        btn_cd.setObjectName("btnSecondary")
        btn_cd.clicked.connect(self._go_check)
        v.addWidget(btn_cd)

        btn_back = QPushButton("← Volver")
        btn_back.clicked.connect(lambda: self._set_state(self.S_TASK))
        btn_back.setStyleSheet(
            "QPushButton{color:#5A8FAA;background:transparent;border:none;"
            "font-size:13px;padding:4px;}"
        )
        v.addWidget(btn_back, 0, Qt.AlignmentFlag.AlignLeft)
        v.addStretch()
        self.panels.addWidget(w)

    def _build_check_panel(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.setContentsMargins(0, 6, 0, 6)
        v.setSpacing(10)

        heading = QLabel("Dígito de Control del rack")
        heading.setObjectName("taskInstruction")
        heading.setAlignment(Qt.AlignmentFlag.AlignCenter)
        v.addWidget(heading)

        self.check_hint_lbl = QLabel("Código de 2 dígitos en la etiqueta del rack")
        self.check_hint_lbl.setObjectName("checkHint")
        self.check_hint_lbl.setWordWrap(True)
        v.addWidget(self.check_hint_lbl)

        kf = QFrame()
        kf.setObjectName("keypadFrame")
        kv = QVBoxLayout(kf)
        kv.setContentsMargins(16, 14, 16, 14)
        kv.setSpacing(10)

        self.check_display = QLabel("_ _")
        self.check_display.setObjectName("checkDisplay")
        kv.addWidget(self.check_display, 0, Qt.AlignmentFlag.AlignCenter)

        grid = QGridLayout()
        grid.setSpacing(8)
        for i, d in enumerate(("1","2","3","4","5","6","7","8","9")):
            btn = QPushButton(d)
            btn.setObjectName("keyBtn")
            btn.clicked.connect(lambda _, c=d: self._check_key(c))
            grid.addWidget(btn, i // 3, i % 3)
        btn0 = QPushButton("0")
        btn0.setObjectName("keyBtn")
        btn0.clicked.connect(lambda: self._check_key("0"))
        grid.addWidget(btn0, 3, 1)
        btn_del = QPushButton("Borrar")
        btn_del.setObjectName("keyDel")
        btn_del.clicked.connect(self._check_del)
        grid.addWidget(btn_del, 3, 2)
        kv.addLayout(grid)

        self.btn_validate_check = QPushButton("Validar digito de control")
        self.btn_validate_check.setObjectName("keyValidate")
        self.btn_validate_check.setEnabled(False)
        self.btn_validate_check.clicked.connect(self._validate_check)
        kv.addWidget(self.btn_validate_check)
        v.addWidget(kf)

        btn_back = QPushButton("← Volver a escanear")
        btn_back.clicked.connect(lambda: self._set_state(self.S_SCAN))
        btn_back.setStyleSheet(
            "QPushButton{color:#5A8FAA;background:transparent;border:none;"
            "font-size:13px;padding:4px;}"
        )
        v.addWidget(btn_back, 0, Qt.AlignmentFlag.AlignLeft)
        v.addStretch()
        self.panels.addWidget(w)

    def _build_ok_panel(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.setContentsMargins(0, 8, 0, 8)
        v.setSpacing(10)

        ok_f = QFrame()
        ok_f.setObjectName("validatedFrame")
        fv = QVBoxLayout(ok_f)
        fv.setContentsMargins(22, 18, 22, 18)
        fv.setSpacing(10)



        txt = QLabel("Ubicación verificada")
        txt.setObjectName("validatedText")
        fv.addWidget(txt)

        self.ok_product_lbl = QLabel("")
        self.ok_product_lbl.setObjectName("taskStore")
        self.ok_product_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.ok_product_lbl.setWordWrap(True)
        fv.addWidget(self.ok_product_lbl)

        self.ok_qty_lbl = QLabel("")
        self.ok_qty_lbl.setObjectName("taskQty")
        self.ok_qty_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        fv.addWidget(self.ok_qty_lbl)

        self.btn_confirm_total = QPushButton("CONFIRMAR TOTAL")
        self.btn_confirm_total.setObjectName("btnConfirm")
        self.btn_confirm_total.clicked.connect(self._confirm_full)
        fv.addWidget(self.btn_confirm_total)
        v.addWidget(ok_f)

        self.btn_faltante_ok = QPushButton("No encontre la cantidad completa")
        self.btn_faltante_ok.setObjectName("btnFaltante")
        self.btn_faltante_ok.clicked.connect(lambda: self._go_short(from_ok=True))
        v.addWidget(self.btn_faltante_ok)

        self.btn_incident_ok = QPushButton("Registrar incidencia")
        self.btn_incident_ok.setObjectName("btnIncident")
        self.btn_incident_ok.clicked.connect(self.report_problem)
        v.addWidget(self.btn_incident_ok)

        v.addStretch()
        self.panels.addWidget(w)

    def _build_short_panel(self):
        w = QWidget()
        v = QVBoxLayout(w)
        v.setContentsMargins(0, 6, 0, 6)
        v.setSpacing(10)

        sf = QFrame()
        sf.setObjectName("faltanteFrame")
        fv = QVBoxLayout(sf)
        fv.setContentsMargins(18, 14, 18, 14)
        fv.setSpacing(10)

        title = QLabel("¿Cuántas piezas encontraste?")
        title.setObjectName("faltanteTitle")
        fv.addWidget(title)

        self.short_display = QLabel("0")
        self.short_display.setObjectName("faltanteQty")
        fv.addWidget(self.short_display)

        self.short_of_lbl = QLabel("")
        self.short_of_lbl.setObjectName("checkHint")
        fv.addWidget(self.short_of_lbl)

        sgrid = QGridLayout()
        sgrid.setSpacing(8)
        for i, d in enumerate(("1","2","3","4","5","6","7","8","9")):
            btn = QPushButton(d)
            btn.setObjectName("keyBtn")
            btn.clicked.connect(lambda _, c=d: self._short_key(c))
            sgrid.addWidget(btn, i // 3, i % 3)
        btn0s = QPushButton("0")
        btn0s.setObjectName("keyBtn")
        btn0s.clicked.connect(lambda: self._short_key("0"))
        sgrid.addWidget(btn0s, 3, 1)
        btn_dels = QPushButton("Borrar")
        btn_dels.setObjectName("keyDel")
        btn_dels.clicked.connect(self._short_del)
        sgrid.addWidget(btn_dels, 3, 2)
        fv.addLayout(sgrid)

        self.btn_confirm_short = QPushButton("Confirmar cantidad parcial")
        self.btn_confirm_short.setObjectName("faltanteConfirm")
        self.btn_confirm_short.setEnabled(False)
        self.btn_confirm_short.clicked.connect(self._confirm_short)
        fv.addWidget(self.btn_confirm_short)
        v.addWidget(sf)

        btn_cancel = QPushButton("← Cancelar")
        btn_cancel.clicked.connect(self._cancel_short)
        btn_cancel.setStyleSheet(
            "QPushButton{color:#5A8FAA;background:transparent;border:none;"
            "font-size:13px;padding:4px;}"
        )
        v.addWidget(btn_cancel, 0, Qt.AlignmentFlag.AlignLeft)
        v.addStretch()
        self.panels.addWidget(w)

    # ── State machine ──────────────────────────────────────────────────────

    def _set_state(self, s: int):
        self.panels.setCurrentIndex(s)

    def _primary_action(self):
        """Route to scan panel for pick; direct confirm for pack/stage/load."""
        if not self.task:
            return
        if self.task.get("expected_scan"):
            self._go_scan()
        else:
            self._go_ok()

    def _go_scan(self):
        if not self.task:
            return
        self.scan_input.clear()
        expected = self.task.get("expected_scan") or ""
        cd = self.task.get("check_digit") or "—"
        self.scan_heading.setText(f"Escanea la etiqueta de: {expected}")
        self.scan_expected_lbl.setText(
            f"Código esperado: {expected}   ·   Dígito de control: {cd}"
        )
        self._set_state(self.S_SCAN)

    def _go_check(self):
        self._check_buf = ""
        self.check_display.setText("_ _")
        self.btn_validate_check.setEnabled(False)
        expected = (self.task.get("expected_scan") or "") if self.task else ""
        self.check_hint_lbl.setText(
            f"Rack: {expected}   ·   Teclea el código de 2 dígitos de la etiqueta física"
        )
        self._set_state(self.S_CHECK)

    def _try_scan(self):
        code = self.scan_input.text().strip().upper()
        expected = (self.task.get("expected_scan") or "").strip().upper() if self.task else ""
        if not expected or code == expected:
            self.status_lbl.setText("✓ Código coincide.")
            self._go_ok()
        else:
            self.status_lbl.setText(f"'{code}' no coincide con '{expected}'. Intenta de nuevo.")

    def _check_key(self, d: str):
        if len(self._check_buf) >= 2:
            return
        self._check_buf += d
        buf = self._check_buf.ljust(2, "_")
        self.check_display.setText(buf[0] + " " + buf[1])
        self.btn_validate_check.setEnabled(len(self._check_buf) == 2)

    def _check_del(self):
        self._check_buf = self._check_buf[:-1]
        buf = self._check_buf.ljust(2, "_")
        self.check_display.setText(buf[0] + " " + buf[1])
        self.btn_validate_check.setEnabled(False)

    def _validate_check(self):
        expected_cd = (self.task.get("check_digit") or "") if self.task else ""
        if self._check_buf == expected_cd:
            self.status_lbl.setText("✓ Dígito de control correcto.")
            self._go_ok()
        else:
            self.status_lbl.setText("Dígito incorrecto — verifica la etiqueta del rack.")
            self._check_buf = ""
            self.check_display.setText("_ _")
            self.btn_validate_check.setEnabled(False)

    def _go_ok(self):
        task = self.task
        if not task:
            return
        qty = task["quantity"]
        self.ok_product_lbl.setText(task["product"])
        self.ok_qty_lbl.setText(f"{number(qty)} piezas")
        self.btn_confirm_total.setText(f"CONFIRMAR TOTAL  ({number(qty)} PZA)")
        can_adj = task.get("can_adjust", False)
        self.btn_faltante_ok.setVisible(can_adj)
        self._set_state(self.S_OK)
        self.status_lbl.setText("Confirma cuando hayas realizado la operación.")

    def _go_short(self, from_ok: bool = False):
        if not self.task or not self.task.get("can_adjust"):
            return
        self._short_from = self.S_OK if from_ok else self.S_TASK
        self._short_str = "0"
        self.short_display.setText("0")
        self.short_of_lbl.setText(f"de {number(self.task['quantity'])} solicitadas")
        self.btn_confirm_short.setEnabled(False)
        self._set_state(self.S_SHORT)

    def _short_key(self, d: str):
        if self._short_str == "0":
            self._short_str = d
        else:
            self._short_str += d
        max_qty = self.task["quantity"] if self.task else 99999
        val = min(int(self._short_str or "0"), max_qty)
        self._short_str = str(val)
        self.short_display.setText(self._short_str)
        self.btn_confirm_short.setEnabled(0 < val < max_qty)

    def _short_del(self):
        self._short_str = self._short_str[:-1] or "0"
        self.short_display.setText(self._short_str)
        max_qty = self.task["quantity"] if self.task else 99999
        self.btn_confirm_short.setEnabled(0 < int(self._short_str) < max_qty)

    def _cancel_short(self):
        self._set_state(self._short_from)

    def _confirm_full(self):
        if not self.task:
            return
        payload = dict(self.task["payload"])
        self.pending = dict(action=self.task["action"], key=str(uuid4()), payload=payload)
        self.send_pending()

    def _confirm_short(self):
        if not self.task:
            return
        qty = int(self._short_str)
        max_qty = self.task["quantity"]
        if not (0 < qty < max_qty):
            return
        payload = dict(self.task["payload"])
        payload["quantity"] = qty
        self.pending = dict(action=self.task["action"], key=str(uuid4()), payload=payload)
        self.send_pending()

    # ── API interaction ────────────────────────────────────────────────────

    def _idle_action(self):
        """Resume from pause or trigger a normal refresh."""
        if self.paused:
            self.paused = False
            self.status_lbl.setText("Reanudando…")
        self.refresh()

    def run(self, fn, done):
        if self.jobs:
            return
        def safe():
            try:
                return dict(ok=True, value=fn())
            except Exception as e:
                return dict(ok=False, error=str(e), status=getattr(e, "status_code", None))

        job = Job(safe)
        self.jobs.add(job)
        self.progress.show()
        self.panels.setEnabled(False)
        self.btn_refresh.setEnabled(False)
        self.btn_admin.setEnabled(False)

        def finish(result):
            self.jobs.discard(job)
            self.progress.hide()
            self.panels.setEnabled(True)
            self.btn_refresh.setEnabled(True)
            self.btn_admin.setEnabled(True)
            if result["ok"]:
                done(result["value"])
                return
            self.status_lbl.setText(result["error"])
            if self.pending and result.get("status") in (400, 401, 403, 404, 409, 422):
                # Server rejected the operation — discard and reset.
                self.pending = None
                self.task = None
                self._set_state(self.S_IDLE)
                self.idle_msg.setText("Error de validación. Actualiza para continuar.")
                self.idle_btn.setText("Actualizar tareas")
            elif self.pending:
                # Network / 5xx — offer retry from the OK panel.
                self.btn_confirm_total.setText("Reintentar confirmación")
                self._set_state(self.S_OK)
            else:
                self.task = None
                self._set_state(self.S_IDLE)
                self.idle_msg.setText("Sin conexión. Toca actualizar cuando haya red.")
                self.idle_btn.setText("Reintentar conexión")

        job.signals.done.connect(finish)
        self.pool.start(job)

    def refresh(self):
        if self.pending or self.paused:
            return
        params = {} if self.preferred is None else {"preferred_allocation": self.preferred}
        self.run(
            lambda: self.api.request("GET", "/demo/operator", params=params),
            self.render,
        )

    def render(self, state: dict):
        self.state = state
        self.task = state.get("task")
        self.paused = False
        task = self.task

        if not task:
            self.idle_msg.setText(state.get("message", "Sin tareas pendientes."))
            self.idle_btn.setText("Buscar siguiente tarea")
            self._set_state(self.S_IDLE)
        else:
            self.preferred = task["allocation_id"]

            # ── Location card ─────────────────────────────────
            src = task["source"]   # "Almacén Norte · Rack A01 (R01-A03)"
            loc_code = src.split("(")[-1].rstrip(")") if "(" in src else src
            self.loc_code.setText(loc_code)

            src_labels = {
                "pick":  ("RECOGE EN",       "LLEVA A"),
                "pack":  ("LO RECOGISTE EN", "EMPACA EN"),
                "stage": ("TARIMA EN",        "LLEVA A"),
                "load":  ("TARIMA EN",        "CARGA EN"),
            }
            lbl_from, lbl_to = src_labels.get(task["action"], ("ORIGEN", "DESTINO"))
            self.loc_from_lbl.setText(lbl_from)
            self.loc_to_lbl.setText(lbl_to)
            self.loc_dest.setText(task["destination"])

            # ── Task info card ────────────────────────────────
            instr_map = {
                "pick":  "RECOGE ESTE PRODUCTO",
                "pack":  "EMPACA LO QUE RECOGISTE",
                "stage": "LLEVA ESTA TARIMA AL ÁREA DE SALIDA",
                "load":  "CARGA ESTA TARIMA AL TRÁILER",
            }
            self.task_instr.setText(instr_map.get(task["action"], "TU TAREA"))
            self.task_product.setText(task["product"])
            self.task_qty.setText(number(task["quantity"]))
            self.task_store.setText("Para: " + task["store"])

            ref = "Pedido " + task["order"]
            if task.get("scheduled_date"):
                ref += "  ·  Día planeado: " + task["scheduled_date"]
            if task.get("hu"):
                ref += "  ·  Tarima " + task["hu"]
            self.task_ref.setText(ref)

            # ── Button visibility ─────────────────────────────
            needs_scan = bool(task.get("expected_scan"))
            can_adj = task.get("can_adjust", False)

            self.btn_primary.setText(
                "📷  Escanear Ubicación" if needs_scan else "✓  Confirmar y continuar"
            )
            self.btn_use_check.setVisible(needs_scan)
            self.btn_faltante_t.setVisible(can_adj)

            self._set_state(self.S_TASK)

        # ── Step strip ────────────────────────────────────────
        for i, lbl in enumerate(self.step_labels, 1):
            active = task is not None and task.get("step") == i
            lbl.setObjectName("stepActive" if active else "stepLabel")
            lbl.style().unpolish(lbl)
            lbl.style().polish(lbl)

        if self.status_lbl.text().startswith("Buscando"):
            self.status_lbl.setText("Una tarea a la vez. Sigue los pasos en orden.")

    def send_pending(self):
        request = dict(self.pending)

        def done(result):
            self.pending = None
            if request["action"] == "incident":
                self.paused = True
                self.status_lbl.setText(
                    "Incidencia registrada. Avisa al supervisor. Pantalla en pausa."
                )
                self._set_state(self.S_IDLE)
                self.idle_msg.setText(
                    "Pantalla en pausa. Toca 'Reanudar' cuando el supervisor lo autorice."
                )
                self.idle_btn.setText("Reanudar después de revisar")
                return
            msgs = {
                "pick":  "Recogida guardada. Sigue al siguiente paso.",
                "pack":  "Empaque guardado. Lleva la tarima al área de salida.",
                "stage": "Traslado guardado. Buscando tu siguiente tarea.",
                "load":  "Carga guardada. Buscando tu siguiente tarea.",
            }
            self.status_lbl.setText(msgs.get(request["action"], "Operación guardada."))
            self.task = None
            self.refresh()

        self.run(
            lambda: self.api.request(
                "POST",
                "/demo/commands/" + request["action"],
                json={"key": request["key"], "payload": request["payload"]},
            ),
            done,
        )

    def report_problem(self):
        if not self.task or self.jobs or self.pending:
            return
        dialog = QDialog(self)
        dialog.setWindowTitle("Reportar problema")
        dialog.setMinimumWidth(320)
        layout = QVBoxLayout(dialog)
        layout.addWidget(label(self.task["product"], "section"))
        reason = QComboBox()
        reason.addItems([
            "Falta producto",
            "Producto dañado",
            "No encuentro la ubicación",
            "Otro problema",
        ])
        layout.addWidget(reason)
        note = QPlainTextEdit()
        note.setPlaceholderText("Detalle opcional")
        note.setMaximumHeight(100)
        layout.addWidget(note)
        layout.addWidget(
            label(
                "Se registra una incidencia y esta pantalla queda en pausa. "
                "Avisa al supervisor.",
                "muted",
            )
        )
        controls = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        controls.button(QDialogButtonBox.StandardButton.Ok).setText("Registrar problema")
        controls.button(QDialogButtonBox.StandardButton.Cancel).setText("Volver")
        controls.accepted.connect(dialog.accept)
        controls.rejected.connect(dialog.reject)
        layout.addWidget(controls)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            text = (
                f'{reason.currentText()} · {self.task["product"]} · '
                f'{note.toPlainText().strip()}'
            )[:1000]
            self.pending = dict(
                action="incident",
                key=str(uuid4()),
                payload=dict(id=self.task["line_id"], reason=text),
            )
            self.send_pending()

    def open_admin(self):
        if self.jobs or self.pending:
            return
        if self.admin is None:
            from frontend.desktop.window import Window
            self.admin = Window(self.api)
            self.admin.operator_requested.connect(self.return_to_operator)
            self.admin.setWindowTitle("Mi almacén | Supervisión (demo)")
            self.admin.statusBar().addPermanentWidget(
                button("Volver al montacarguista", self.return_to_operator)
            )
            self.admin.nav.setCurrentRow(0)
        self.admin.show()
        self.admin.raise_()
        self.admin.activateWindow()
        self.admin.refresh()

    def return_to_operator(self):
        if self.admin and self.admin.jobs:
            return
        if self.admin:
            self.admin.hide()
        self.showNormal()
        self.raise_()
        self.activateWindow()
        self.refresh()

    def closeEvent(self, event):
        if self.jobs or (self.admin and self.admin.jobs):
            self.status_lbl.setText("Espera a que termine el guardado antes de cerrar.")
            event.ignore()
            return
        if self.pending:
            self.status_lbl.setText("Reintenta la confirmación antes de cerrar.")
            event.ignore()
            return
        if self.admin:
            self.admin.close()
        event.accept()
