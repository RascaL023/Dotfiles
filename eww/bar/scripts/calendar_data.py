"""Small, locale-independent Monday-first calendar; no I/O or timers."""
import calendar
import datetime

MONTHS = ("January", "February", "March", "April", "May", "June", "July",
          "August", "September", "October", "November", "December")
WEEKDAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")


def calendar_state(year=None, month=None, *, today=None, opened=False):
    today = today or datetime.date.today()
    year = today.year if year is None else year
    month = today.month if month is None else month
    # datetime validates both ends of the navigable range, including leap years.
    datetime.date(year, month, 1)
    weeks = calendar.Calendar(firstweekday=calendar.MONDAY).monthdayscalendar(year, month)
    weeks += [[0] * 7 for _ in range(6 - len(weeks))]
    return {
        "open": opened, "year": year, "month": month, "date": today.isoformat(),
        "day": str(today.day), "weekday": WEEKDAYS[today.weekday()],
        "month_year": f"{MONTHS[today.month - 1]} {today.year}",
        "heading": f"{MONTHS[month - 1]} {year}",
        "previous": (year, month) > (1, 1), "next": (year, month) < (9999, 12),
        "weekdays": ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        "weeks": [[{"label": str(day) if day else "", "today": bool(day) and
                    (year, month, day) == (today.year, today.month, today.day)}
                   for day in week] for week in weeks],
    }


def shift_month(year, month, delta):
    index = (year - 1) * 12 + month - 1 + delta
    index = max(0, min(9999 * 12 - 1, index))
    return index // 12 + 1, index % 12 + 1
