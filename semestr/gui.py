#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GUI для семестровой работы
"Учет товарооборота розничных торговых предприятий"

Технологии: Python 3, tkinter (ttk), cx_Oracle
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
from datetime import datetime
import os

try:
    import cx_Oracle
except ImportError:
    try:
        import oracledb as cx_Oracle
    except ImportError:
        cx_Oracle = None

# ============================================================
# Стили и константы
# ============================================================
COLORS = {
    "bg": "#f0f2f5",
    "frame_bg": "#ffffff",
    "accent": "#2c3e50",
    "primary": "#3498db",
    "success": "#27ae60",
    "danger": "#e74c3c",
    "warning": "#f39c12",
    "text": "#2c3e50",
    "light_text": "#7f8c8d"
}

FONT = ("Segoe UI", 10)
FONT_BOLD = ("Segoe UI", 10, "bold")
FONT_HEADER = ("Segoe UI", 12, "bold")
FONT_TITLE = ("Segoe UI", 14, "bold")


# ============================================================
# Класс для работы с БД
# ============================================================
class Database:
    def __init__(self):
        self.conn = None
        self.cursor = None

    def connect(self, user, password, host, port, service):
        if cx_Oracle is None:
            raise RuntimeError("Библиотека cx_Oracle не установлена. Установите: pip install cx_Oracle")
        dsn = cx_Oracle.makedsn(host, port, service_name=service)
        self.conn = cx_Oracle.connect(user=user, password=password, dsn=dsn)
        self.cursor = self.conn.cursor()
        return True

    def disconnect(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.cursor = None
        self.conn = None

    def is_connected(self):
        return self.conn is not None

    def fetchall(self, sql, params=None):
        self.cursor.execute(sql, params or {})
        cols = [desc[0] for desc in self.cursor.description]
        rows = self.cursor.fetchall()
        return cols, rows

    def execute(self, sql, params=None):
        self.cursor.execute(sql, params or {})
        self.conn.commit()

    def call_proc(self, proc_name, params):
        """Вызов хранимой процедуры через CALL"""
        placeholders = ",".join([f":{i+1}" for i in range(len(params))])
        self.cursor.execute(f"BEGIN {proc_name}({placeholders}); END;", params)
        self.conn.commit()

    def call_func(self, func_name, return_type, params):
        """Вызов функции"""
        result = self.cursor.callfunc(func_name, return_type, params)
        return result


# ============================================================
# Вспомогательные функции
# ============================================================
def style_tree(tree):
    tree.tag_configure("odd", background="#fafafa")
    tree.tag_configure("even", background="#ffffff")


def clear_tree(tree):
    for item in tree.get_children():
        tree.delete(item)


def populate_tree(tree, cols, rows):
    clear_tree(tree)
    tree["columns"] = cols
    tree.heading("#0", text="#")
    tree.column("#0", width=40, anchor="center")
    for col in cols:
        tree.heading(col, text=col)
        tree.column(col, width=120, anchor="w")
    for i, row in enumerate(rows):
        tag = "even" if i % 2 == 0 else "odd"
        tree.insert("", "end", text=str(i + 1), values=row, tags=(tag,))


# ============================================================
# Универсальная вкладка CRUD
# ============================================================
class CRUDTab:
    def __init__(self, parent, db, title, table, columns, pk_column, form_fields, id_field_visible=False):
        self.db = db
        self.table = table
        self.pk_column = pk_column
        self.columns = columns
        self.form_fields = form_fields  # список словарей с описанием полей
        self.id_field_visible = id_field_visible

        self.frame = ttk.Frame(parent)
        self.frame.pack(fill="both", expand=True)

        # -- Заголовок --
        lbl = tk.Label(self.frame, text=title, font=FONT_HEADER, bg=COLORS["frame_bg"], fg=COLORS["accent"])
        lbl.pack(anchor="w", padx=10, pady=(10, 5))

        # -- Таблица данных --
        table_frame = tk.LabelFrame(self.frame, text=" Данные ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        table_frame.pack(fill="both", expand=True, padx=10, pady=5)

        cols = [f["col"] for f in form_fields]
        self.tree = ttk.Treeview(table_frame, columns=cols, show="headings", height=10)
        for col in cols:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=130, anchor="w")
        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")
        table_frame.grid_rowconfigure(0, weight=1)
        table_frame.grid_columnconfigure(0, weight=1)
        style_tree(self.tree)
        self.tree.bind("<<TreeviewSelect>>", self.on_select)

        btn_refresh = tk.Button(table_frame, text="🔄 Обновить", command=self.load_data,
                                bg=COLORS["primary"], fg="white", font=FONT_BOLD, relief="flat", cursor="hand2")
        btn_refresh.grid(row=2, column=0, columnspan=2, sticky="ew", padx=5, pady=5)

        # -- Форма управления --
        form_frame = tk.LabelFrame(self.frame, text=" Управление ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        form_frame.pack(fill="x", padx=10, pady=5)

        self.entries = {}
        self.current_id = None
        if not self.id_field_visible:
            self.lbl_id = tk.Label(form_frame, text="Выбран ID: (нет)", bg=COLORS["frame_bg"],
                                   fg=COLORS["primary"], font=FONT_BOLD)
            self.lbl_id.grid(row=0, column=0, columnspan=6, sticky="e", padx=10, pady=(5, 0))

        for i, field in enumerate(form_fields):
            row = 1 + (i // 3)
            col_lbl = (i % 3) * 2
            col_ent = col_lbl + 1
            lbl = tk.Label(form_frame, text=field["label"] + ":", bg=COLORS["frame_bg"], fg=COLORS["text"], font=FONT)
            lbl.grid(row=row, column=col_lbl, sticky="e", padx=5, pady=5)
            ent = ttk.Entry(form_frame, width=22)
            ent.grid(row=row, column=col_ent, sticky="w", padx=5, pady=5)
            self.entries[field["col"]] = ent

        # -- Кнопки --
        btn_frame = tk.Frame(form_frame, bg=COLORS["frame_bg"])
        btn_row = 2 + (len(form_fields) - 1) // 3
        btn_frame.grid(row=btn_row, column=0, columnspan=6, pady=(10, 5))

        tk.Button(btn_frame, text="➕ Добавить", command=self.add,
                  bg=COLORS["success"], fg="white", font=FONT_BOLD, relief="flat", width=14, cursor="hand2").pack(side="left", padx=5)
        tk.Button(btn_frame, text="💾 Изменить", command=self.update,
                  bg=COLORS["warning"], fg="white", font=FONT_BOLD, relief="flat", width=14, cursor="hand2").pack(side="left", padx=5)
        tk.Button(btn_frame, text="❌ Удалить", command=self.delete,
                  bg=COLORS["danger"], fg="white", font=FONT_BOLD, relief="flat", width=14, cursor="hand2").pack(side="left", padx=5)
        tk.Button(btn_frame, text="🧹 Очистить", command=self.clear_form,
                  bg=COLORS["light_text"], fg="white", font=FONT_BOLD, relief="flat", width=14, cursor="hand2").pack(side="left", padx=5)

        self.load_data()

    def quote_col(self, col):
        reserved = {'DATE', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ORDER', 'GROUP', 'FROM', 'WHERE'}
        if col.upper() in reserved:
            return f'"{col.lower()}"'
        return col

    def load_data(self):
        if not self.db.is_connected():
            return
        try:
            cols = [f["col"] for f in self.form_fields]
            quoted_cols = [self.quote_col(c) for c in cols]
            sql = f"SELECT {', '.join(quoted_cols)} FROM {self.table} ORDER BY {self.quote_col(self.pk_column)}"
            _, rows = self.db.fetchall(sql)
            populate_tree(self.tree, cols, rows)
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def on_select(self, event):
        sel = self.tree.selection()
        if not sel:
            return
        values = self.tree.item(sel[0], "values")
        self.current_id = values[0]
        if hasattr(self, 'lbl_id'):
            self.lbl_id.config(text=f"Выбран ID: {self.current_id}")
        for i, field in enumerate(self.form_fields):
            ent = self.entries[field["col"]]
            ent.config(state="normal")
            ent.delete(0, tk.END)
            if values[i] is not None:
                ent.insert(0, str(values[i]))

    def get_form_values(self):
        result = {}
        for field in self.form_fields:
            val = self.entries[field["col"]].get().strip()
            if field.get("type") == "number":
                result[field["col"]] = float(val) if val else None
            elif field.get("type") == "int":
                result[field["col"]] = int(val) if val else None
            else:
                result[field["col"]] = val if val else None
        return result

    def clear_form(self):
        self.current_id = None
        if hasattr(self, 'lbl_id'):
            self.lbl_id.config(text="Выбран ID: (нет)")
        for field in self.form_fields:
            ent = self.entries[field["col"]]
            ent.config(state="normal")
            ent.delete(0, tk.END)

    def add(self):
        if not self.db.is_connected():
            return
        try:
            vals = self.get_form_values()
            # Убираем PK из вставки (identity)
            cols = [f["col"] for f in self.form_fields if f["col"] != self.pk_column]
            placeholders = ",".join([f":{c}" for c in cols])
            quoted_cols = [self.quote_col(c) for c in cols]
            sql = f"INSERT INTO {self.table} ({', '.join(quoted_cols)}) VALUES ({placeholders})"
            params = {c: vals[c] for c in cols}
            self.db.execute(sql, params)
            messagebox.showinfo("Успех", "Запись добавлена")
            self.load_data()
            self.clear_form()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def update(self):
        if not self.db.is_connected():
            return
        try:
            vals = self.get_form_values()
            pk_val = vals[self.pk_column]
            if pk_val is None or str(pk_val).strip() == "":
                messagebox.showwarning("Внимание", "Выберите запись для изменения")
                return
            cols = [f["col"] for f in self.form_fields if f["col"] != self.pk_column]
            set_clause = ", ".join([f"{self.quote_col(c)} = :{c}" for c in cols])
            sql = f"UPDATE {self.table} SET {set_clause} WHERE {self.quote_col(self.pk_column)} = :pk"
            params = {c: vals[c] for c in cols}
            params["pk"] = pk_val
            self.db.execute(sql, params)
            messagebox.showinfo("Успех", "Запись обновлена")
            self.load_data()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def delete(self):
        if not self.db.is_connected():
            return
        try:
            vals = self.get_form_values()
            pk_val = vals[self.pk_column]
            if pk_val is None or str(pk_val).strip() == "":
                messagebox.showwarning("Внимание", "Выберите запись для удаления")
                return
            if not messagebox.askyesno("Подтверждение", f"Удалить запись с ID={pk_val}?"):
                return
            sql = f"DELETE FROM {self.table} WHERE {self.pk_column} = :pk"
            self.db.execute(sql, {"pk": pk_val})
            messagebox.showinfo("Успех", "Запись удалена")
            self.load_data()
            self.clear_form()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))


# ============================================================
# Вкладка аудита (Лог)
# ============================================================
class LogTab:
    def __init__(self, parent, db):
        self.db = db
        self.frame = ttk.Frame(parent)
        self.frame.pack(fill="both", expand=True)

        lbl = tk.Label(self.frame, text="Журнал аудита", font=FONT_HEADER, bg=COLORS["frame_bg"], fg=COLORS["accent"])
        lbl.pack(anchor="w", padx=10, pady=(10, 5))

        # -- Фильтры --
        filt_frame = tk.LabelFrame(self.frame, text=" Фильтры ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        filt_frame.pack(fill="x", padx=10, pady=5)

        tk.Label(filt_frame, text="С:", bg=COLORS["frame_bg"], font=FONT).grid(row=0, column=0, padx=5, pady=5, sticky="e")
        self.ent_from = ttk.Entry(filt_frame, width=20)
        self.ent_from.grid(row=0, column=1, padx=5, pady=5)
        self.ent_from.insert(0, "")

        tk.Label(filt_frame, text="По:", bg=COLORS["frame_bg"], font=FONT).grid(row=0, column=2, padx=5, pady=5, sticky="e")
        self.ent_to = ttk.Entry(filt_frame, width=20)
        self.ent_to.grid(row=0, column=3, padx=5, pady=5)

        tk.Label(filt_frame, text="Тип:", bg=COLORS["frame_bg"], font=FONT).grid(row=0, column=4, padx=5, pady=5, sticky="e")
        self.cmb_op = ttk.Combobox(filt_frame, values=["", "INSERT", "UPDATE", "DELETE"], width=12, state="readonly")
        self.cmb_op.grid(row=0, column=5, padx=5, pady=5)
        self.cmb_op.set("")

        tk.Label(filt_frame, text="Сущность:", bg=COLORS["frame_bg"], font=FONT).grid(row=0, column=6, padx=5, pady=5, sticky="e")
        self.cmb_table = ttk.Combobox(filt_frame, values=["", "SELLERS", "CUSTOMERS", "SALES"], width=12, state="readonly")
        self.cmb_table.grid(row=0, column=7, padx=5, pady=5)
        self.cmb_table.set("")

        btn_search = tk.Button(filt_frame, text="🔍 Показать", command=self.load_log,
                               bg=COLORS["primary"], fg="white", font=FONT_BOLD, relief="flat", cursor="hand2")
        btn_search.grid(row=0, column=8, padx=10, pady=5)

        # -- Таблица лога --
        log_frame = tk.LabelFrame(self.frame, text=" Записи лога ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        log_frame.pack(fill="both", expand=True, padx=10, pady=5)

        self.tree = ttk.Treeview(log_frame, columns=("ID", "TABLE", "OP", "TIMESTAMP", "PK", "USER"), show="headings", height=12)
        for col, w in [("ID", 50), ("TABLE", 100), ("OP", 80), ("TIMESTAMP", 150), ("PK", 60), ("USER", 100)]:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=w, anchor="w")
        vsb = ttk.Scrollbar(log_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        log_frame.grid_rowconfigure(0, weight=1)
        log_frame.grid_columnconfigure(0, weight=1)
        style_tree(self.tree)

        # -- Кнопка отката --
        btn_rollback = tk.Button(self.frame, text="↩️ Откатить выбранную операцию", command=self.rollback,
                                 bg=COLORS["danger"], fg="white", font=FONT_BOLD, relief="flat", cursor="hand2")
        btn_rollback.pack(fill="x", padx=10, pady=5)

        self.load_log()

    def load_log(self):
        if not self.db.is_connected():
            return
        try:
            sql = """SELECT id, table_name, operation,
                            TO_CHAR(op_timestamp, 'DD.MM.YYYY HH24:MI:SS') as ts,
                            record_pk, db_user
                     FROM audit_log
                     WHERE 1=1"""
            params = {}
            df = self.ent_from.get().strip()
            dt = self.ent_to.get().strip()
            op = self.cmb_op.get()
            tbl = self.cmb_table.get()
            if df:
                sql += " AND op_timestamp >= TO_TIMESTAMP(:df, 'DD.MM.YYYY HH24:MI:SS')"
                params["df"] = df
            if dt:
                sql += " AND op_timestamp <= TO_TIMESTAMP(:dt, 'DD.MM.YYYY HH24:MI:SS')"
                params["dt"] = dt
            if op:
                sql += " AND operation = :op"
                params["op"] = op
            if tbl:
                sql += " AND table_name = :tbl"
                params["tbl"] = tbl
            sql += " ORDER BY id DESC"

            _, rows = self.db.fetchall(sql, params)
            populate_tree(self.tree, ["ID", "TABLE", "OP", "TIMESTAMP", "PK", "USER"], rows)
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def rollback(self):
        if not self.db.is_connected():
            return
        sel = self.tree.selection()
        if not sel:
            messagebox.showwarning("Внимание", "Выберите запись лога для отката")
            return
        values = self.tree.item(sel[0], "values")
        log_id = int(values[0])
        if not messagebox.askyesno("Подтверждение", f"Откатить операцию лога ID={log_id}?"):
            return
        try:
            self.db.call_proc("pkg_audit.rollback_operation", [log_id])
            messagebox.showinfo("Успех", f"Операция лога ID={log_id} откатана")
            self.load_log()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))


# ============================================================
# Вкладка отчета
# ============================================================
class ReportTab:
    def __init__(self, parent, db):
        self.db = db
        self.frame = ttk.Frame(parent)
        self.frame.pack(fill="both", expand=True)

        lbl = tk.Label(self.frame, text="Сводный отчет по аудиту", font=FONT_HEADER, bg=COLORS["frame_bg"], fg=COLORS["accent"])
        lbl.pack(anchor="w", padx=10, pady=(10, 5))

        # -- Флаги --
        flags_frame = tk.LabelFrame(self.frame, text=" Параметры сортировки ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        flags_frame.pack(fill="x", padx=10, pady=5)

        self.var_f1 = tk.IntVar(value=0)
        self.var_f2 = tk.IntVar(value=0)
        self.var_f3 = tk.IntVar(value=0)

        tk.Checkbutton(flags_frame, text="Флаг 1: по названию сущности", variable=self.var_f1,
                       bg=COLORS["frame_bg"], font=FONT, selectcolor=COLORS["primary"]).pack(anchor="w", padx=10, pady=2)
        tk.Checkbutton(flags_frame, text="Флаг 2: по типу операции", variable=self.var_f2,
                       bg=COLORS["frame_bg"], font=FONT, selectcolor=COLORS["primary"]).pack(anchor="w", padx=10, pady=2)
        tk.Checkbutton(flags_frame, text="Флаг 3: по количеству выполнений", variable=self.var_f3,
                       bg=COLORS["frame_bg"], font=FONT, selectcolor=COLORS["primary"]).pack(anchor="w", padx=10, pady=2)

        btn_gen = tk.Button(flags_frame, text="📊 Сформировать отчет", command=self.generate,
                            bg=COLORS["success"], fg="white", font=FONT_BOLD, relief="flat", cursor="hand2")
        btn_gen.pack(anchor="w", padx=10, pady=8)

        # -- Результат --
        res_frame = tk.LabelFrame(self.frame, text=" Результат ", bg=COLORS["frame_bg"], fg=COLORS["accent"], font=FONT_BOLD)
        res_frame.pack(fill="both", expand=True, padx=10, pady=5)

        self.tree = ttk.Treeview(res_frame, columns=("TABLE", "OPERATION", "COUNT"), show="headings", height=12)
        for col, w in [("TABLE", 150), ("OPERATION", 120), ("COUNT", 100)]:
            self.tree.heading(col, text=col)
            self.tree.column(col, width=w, anchor="w")
        vsb = ttk.Scrollbar(res_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        res_frame.grid_rowconfigure(0, weight=1)
        res_frame.grid_columnconfigure(0, weight=1)
        style_tree(self.tree)

    def generate(self):
        if not self.db.is_connected():
            return
        try:
            cur = self.db.call_func("pkg_audit.get_report", cx_Oracle.CURSOR,
                                    [self.var_f1.get(), self.var_f2.get(), self.var_f3.get()])
            rows = cur.fetchall()
            cols = [desc[0] for desc in cur.description]
            populate_tree(self.tree, cols, rows)
            cur.close()
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))


# ============================================================
# Главное окно приложения
# ============================================================
class App:
    def __init__(self, root):
        self.root = root
        self.root.title("Учет товарооборота — Семестровая работа")
        self.root.geometry("1100x750")
        self.root.configure(bg=COLORS["bg"])
        self.db = Database()

        self.setup_styles()
        self.build_ui()

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TNotebook", background=COLORS["bg"], tabmargins=[2, 5, 2, 0])
        style.configure("TNotebook.Tab", font=FONT_BOLD, padding=[15, 5], background="#dfe4ea")
        style.map("TNotebook.Tab", background=[("selected", COLORS["primary"])],
                  foreground=[("selected", "white")])
        style.configure("TFrame", background=COLORS["frame_bg"])
        style.configure("TLabel", background=COLORS["frame_bg"], foreground=COLORS["text"], font=FONT)
        style.configure("TEntry", font=FONT)
        style.configure("TCombobox", font=FONT)
        style.configure("Treeview", font=FONT, rowheight=24)
        style.configure("Treeview.Heading", font=FONT_BOLD, background=COLORS["accent"], foreground="white")
        style.map("Treeview", background=[("selected", COLORS["primary"])])

    def build_ui(self):
        # -- Панель подключения --
        conn_frame = tk.LabelFrame(self.root, text=" Подключение к Oracle ", bg=COLORS["frame_bg"],
                                   fg=COLORS["accent"], font=FONT_BOLD)
        conn_frame.pack(fill="x", padx=15, pady=10)

        self.conn_vars = {}
        fields = [
            ("User", "SYSTEM"),
            ("Password", ""),
            ("Host", "localhost"),
            ("Port", "1521"),
            ("Service", "XE")
        ]
        for i, (label, default) in enumerate(fields):
            tk.Label(conn_frame, text=label + ":", bg=COLORS["frame_bg"], font=FONT).grid(row=0, column=i * 2, padx=5, pady=8, sticky="e")
            var = tk.StringVar(value=default)
            self.conn_vars[label.lower()] = var
            show = "*" if label == "Password" else None
            ent = ttk.Entry(conn_frame, textvariable=var, width=18, show=show)
            ent.grid(row=0, column=i * 2 + 1, padx=5, pady=8, sticky="w")

        self.btn_connect = tk.Button(conn_frame, text="🔌 Подключиться", command=self.connect_db,
                                     bg=COLORS["success"], fg="white", font=FONT_BOLD, relief="flat", cursor="hand2")
        self.btn_connect.grid(row=0, column=10, padx=15, pady=8)

        self.lbl_status = tk.Label(conn_frame, text="❌ Нет подключения", bg=COLORS["frame_bg"],
                                   fg=COLORS["danger"], font=FONT_BOLD)
        self.lbl_status.grid(row=0, column=11, padx=10, pady=8)

        # -- Вкладки --
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True, padx=15, pady=(0, 15))

        # CRUD для 3 таблиц
        self.tab_sellers = CRUDTab(self.notebook, self.db, "Продавцы (SELLERS)", "sellers", ["ID", "FULL_NAME", "RETAIL_OUTLET_ID", "SALARY_RATE"],
                                   "ID", [
                                       {"col": "ID", "label": "ID", "type": "int"},
                                       {"col": "FULL_NAME", "label": "ФИО"},
                                       {"col": "RETAIL_OUTLET_ID", "label": "Точка", "type": "int"},
                                       {"col": "SALARY_RATE", "label": "Ставка", "type": "number"}
                                   ])
        self.notebook.add(self.tab_sellers.frame, text="👤 Продавцы")

        self.tab_customers = CRUDTab(self.notebook, self.db, "Покупатели (CUSTOMERS)", "customers",
                                     ["ID", "FULL_NAME", "CHARACTERISTICS"], "ID", [
                                         {"col": "ID", "label": "ID", "type": "int"},
                                         {"col": "FULL_NAME", "label": "ФИО"},
                                         {"col": "CHARACTERISTICS", "label": "Характеристики"}
                                     ])
        self.notebook.add(self.tab_customers.frame, text="🛒 Покупатели")

        self.tab_sales = CRUDTab(self.notebook, self.db, "Продажи (SALES)", "sales",
                                 ["ID", "DATE", "PRODUCT_ID", "QUANTITY", "SALE_PRICE", "SELLER_ID", "RETAIL_OUTLET_ID", "CUSTOMER_ID"],
                                 "ID", [
                                     {"col": "ID", "label": "ID", "type": "int"},
                                     {"col": "date", "label": "Дата"},
                                     {"col": "PRODUCT_ID", "label": "Товар", "type": "int"},
                                     {"col": "QUANTITY", "label": "Кол-во", "type": "number"},
                                     {"col": "SALE_PRICE", "label": "Цена", "type": "number"},
                                     {"col": "SELLER_ID", "label": "Продавец", "type": "int"},
                                     {"col": "RETAIL_OUTLET_ID", "label": "Точка", "type": "int"},
                                     {"col": "CUSTOMER_ID", "label": "Покупатель", "type": "int"}
                                 ])
        self.notebook.add(self.tab_sales.frame, text="💰 Продажи")

        # Аудит
        self.tab_log = LogTab(self.notebook, self.db)
        self.notebook.add(self.tab_log.frame, text="📋 Журнал аудита")

        # Отчет
        self.tab_report = ReportTab(self.notebook, self.db)
        self.notebook.add(self.tab_report.frame, text="📊 Отчет")

    def connect_db(self):
        try:
            user = self.conn_vars["user"].get()
            password = self.conn_vars["password"].get()
            host = self.conn_vars["host"].get()
            port = self.conn_vars["port"].get()
            service = self.conn_vars["service"].get()
            self.db.connect(user, password, host, port, service)
            self.lbl_status.config(text="✅ Подключено", fg=COLORS["success"])
            self.tab_sellers.load_data()
            self.tab_customers.load_data()
            self.tab_sales.load_data()
            self.tab_log.load_log()
        except Exception as e:
            messagebox.showerror("Ошибка подключения", str(e))
            self.lbl_status.config(text="❌ Ошибка", fg=COLORS["danger"])


# ============================================================
# Точка входа
# ============================================================
if __name__ == "__main__":
    root = tk.Tk()
    app = App(root)
    root.mainloop()
