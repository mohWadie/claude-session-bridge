# Closed by backend — 2026-10-09 16:02
**Status:** resolved
**Root cause:** ChequeForm.tsx:88 bound the display string (dd/MM/yyyy) instead of the date value, so the API received non-ISO dates; the converter used DateTime.Parse and threw, producing a 500.
**Fix — backend:** parse dueDate with ParseExact("yyyy-MM-dd"); return 400 with a validation body on failure.
**Fix — frontend:** bind `form.dueDate` and serialize as yyyy-MM-dd.
**Agreements:** all API dates are ISO 8601 yyyy-MM-dd (user approval needed for decisions/).
