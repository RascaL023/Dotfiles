import asyncio
import datetime
from pathlib import Path
import sys
import unittest
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from adapter import Collector
from actions import dispatch
from calendar_data import calendar_state, shift_month
from common import settings


class CalendarData(unittest.TestCase):
    def test_monday_first_leap_day_and_today(self):
        state = calendar_state(today=datetime.date(2024, 2, 29))
        self.assertEqual(state["weeks"][0][3]["label"], "1")  # Thursday
        self.assertEqual(state["weekday"], "Thursday")
        self.assertEqual(state["heading"], "February 2024")
        cells = [cell for week in state["weeks"] for cell in week]
        self.assertEqual(sum(bool(cell["label"]) for cell in cells), 29)
        self.assertEqual([cell["label"] for cell in cells if cell["today"]], ["29"])
        self.assertEqual(len(state["weeks"]), 6)
        other = calendar_state(2024, 3, today=datetime.date(2024, 2, 29))
        self.assertFalse(any(cell["today"] for week in other["weeks"] for cell in week))
        self.assertEqual(other["month_year"], "February 2024")

    def test_six_week_month_and_year_boundaries(self):
        state = calendar_state(2026, 3)
        self.assertEqual(state["weeks"][0][6]["label"], "1")  # Sunday
        self.assertEqual(state["weeks"][5][1]["label"], "31")
        self.assertEqual(shift_month(2026, 12, 1), (2027, 1))
        self.assertEqual(shift_month(2026, 1, -1), (2025, 12))
        self.assertEqual(shift_month(1, 1, -1), (1, 1))
        self.assertEqual(shift_month(9999, 12, 1), (9999, 12))
        self.assertFalse(calendar_state(1, 1)["previous"])
        self.assertFalse(calendar_state(9999, 12)["next"])


class CalendarLifecycle(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.collector = Collector(settings(), lambda _: None)
        self.collector.calendar_eww = AsyncMock(return_value="")
        self.collector.state["ui"]["calendar_duration"] = "0ms"

    async def asyncTearDown(self):
        tasks = list(self.collector.tasks)
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)

    async def test_navigation_toggle_and_reopen_during_close(self):
        collector = self.collector
        await dispatch(collector, "calendar-toggle")
        self.assertTrue(collector.state["calendar"]["open"])
        original = collector.state["calendar"].copy()
        await dispatch(collector, "calendar-next")
        self.assertEqual((collector.state["calendar"]["year"], collector.state["calendar"]["month"]),
                         shift_month(original["year"], original["month"], 1))
        await dispatch(collector, "calendar-today")
        self.assertEqual(collector.state["calendar"]["heading"], original["heading"])
        await dispatch(collector, "calendar-toggle")
        self.assertFalse(collector.state["calendar"]["open"])
        await dispatch(collector, "calendar-toggle")
        await asyncio.sleep(.07)
        self.assertTrue(collector.state["calendar"]["open"])
        self.assertEqual(collector.calendar_eww.await_count, 1)  # Reuse the still-visible window.
        await dispatch(collector, "calendar-toggle")
        await collector.calendar_close_task
        collector.calendar_eww.assert_awaited_with("close", "calendar-popup")
        self.assertFalse(collector.calendar_window)

    async def test_open_failure_is_retryable_and_disabled_clock_rejects(self):
        collector = self.collector
        collector.calendar_eww.return_value = None
        with self.assertRaises(RuntimeError):
            await dispatch(collector, "calendar-toggle")
        self.assertFalse(collector.state["calendar"]["open"])
        self.assertFalse(collector.calendar_window)
        collector.calendar_eww.return_value = ""
        await dispatch(collector, "calendar-toggle")
        self.assertTrue(collector.state["calendar"]["open"])
        collector.cfg["modules"]["clock"] = False
        with self.assertRaises(ValueError):
            await dispatch(collector, "calendar-toggle")

    async def test_midnight_follows_current_month_but_preserves_browsing(self):
        collector = self.collector
        collector.state["calendar"] = calendar_state(today=datetime.date(2026, 12, 31), opened=True)
        with patch("adapter.datetime", wraps=datetime) as dates:
            dates.date.today.return_value = datetime.date(2027, 1, 1)
            dates.date.fromisoformat.side_effect = datetime.date.fromisoformat
            collector.refresh_calendar_date()
        self.assertEqual(collector.state["calendar"]["heading"], "January 2027")
        self.assertTrue(collector.state["calendar"]["open"])
        collector.state["calendar"] = calendar_state(2026, 6, today=datetime.date(2026, 12, 31))
        with patch("adapter.datetime", wraps=datetime) as dates:
            dates.date.today.return_value = datetime.date(2027, 1, 1)
            dates.date.fromisoformat.side_effect = datetime.date.fromisoformat
            collector.refresh_calendar_date()
        self.assertEqual(collector.state["calendar"]["heading"], "June 2026")
        self.assertEqual(collector.state["calendar"]["day"], "1")


if __name__ == "__main__":
    unittest.main()
