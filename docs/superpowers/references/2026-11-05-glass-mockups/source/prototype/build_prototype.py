#!/usr/bin/env python3
"""Builds the clickable Borj prototype (all 39 boards + the motion spec) as one HTML page.
   python3 build_prototype.py <out.html>
Boards come from ../build.py make() unchanged; shell.html + runtime.js add navigation and motion
(docs/superpowers/specs/2026-11-06-motion-and-today-customization-design.md)."""
import importlib.util, json, os, re, sys

D = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("board_build", os.path.join(D, "..", "build.py"))
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)

NAMES = {
    "Main": "امروز", "PhoneEmptyToday": "امروزِ خالی", "PhoneDashboardCards": "کارت‌های امروز", "PhoneOnboarding": "شروع برنامه",
    "PhoneTasks": "کارها", "PhoneKanban": "کانبان", "PhoneCalendar": "تقویم ماه", "PhoneDay": "نمای روز", "PhoneTimer": "زمان‌سنج",
    "PhoneTaskDetail": "جزئیات کار", "PhoneReminderEdit": "یادآور و تکرار", "PhoneQuickEntry": "ورود سریع",
    "PhoneTemplates": "قالب‌ها", "PhoneTemplateEdit": "ویرایش قالب",
    "PhoneMoney": "مالی", "PhoneAddTxn": "تراکنش جدید", "PhoneDebts": "قسط و بدهی", "PhoneReports": "گزارش‌ها",
    "PhoneBudgets": "بودجه‌ها", "PhoneAccounts": "حساب‌ها", "PhoneHabits": "عادت‌ها", "PhoneGoals": "هدف‌ها",
    "PhoneSearch": "جست‌وجو", "PhoneSettings": "تنظیمات", "PhoneNotifications": "اعلان‌ها", "PhoneBackup": "پشتیبان",
    "PhoneImportV1": "انتقال از نسخهٔ ۱", "PhoneTrash": "سطل بازیافت",
    "MacToday": "امروز", "MacTasks": "کارها", "MacCalendar": "تقویم", "MacMoney": "تراکنش‌ها", "MacFinance": "مالی و بودجه",
    "MacDebts": "قسط و بدهی", "MacReports": "گزارش‌ها", "MacHabits": "عادت‌ها", "MacGoals": "هدف‌ها",
    "MacSearch": "جست‌وجو", "MacSettings": "تنظیمات",
}


def split(out):
    css = re.search(r"<helmet>.*?<style>\n(.*?)</style>\s*</helmet>", out, re.S).group(1)
    body = out.split("</helmet>", 1)[1].rsplit("</x-dc>", 1)[0].strip()
    w, h = (int(x) for x in re.search(r'"width":(\d+),"height":(\d+)', out).groups())
    css = css.replace(":root", ":host").replace("body{margin:0}", "")
    body = body.replace("min-height: 100vh", "min-height: 100%")
    return css, body, w, h


docs = {}
for name in NAMES:
    css, light, w, h = split(b.make(name, False))
    _, dark, _, _ = split(b.make(name, True))
    kind = "mac" if name.startswith("Mac") else "phone"
    docs[name] = {"k": kind, "w": w, "h": h, "n": NAMES[name], "css": css, "l": light, "d": dark}

shell = open(os.path.join(D, "shell.html"), encoding="utf-8").read()
runtime = open(os.path.join(D, "runtime.js"), encoding="utf-8").read()
page = shell.replace("/*@DOCS@*/", "const DOCS = " + json.dumps(docs, ensure_ascii=False) + ";").replace("/*@RUNTIME@*/", runtime)
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, "prototype.html")
open(out, "w", encoding="utf-8").write(page)
print(out, len(page.encode()) // 1024, "KiB")
