---
name: kotak-export
description: Download account statements from Kotak Mahindra Bank netbanking via Playwright MCP. Use when the user asks to export, download, or pull Kotak statements / transactions / passbook.
allowed-tools:
  - Bash
  - Read
  - Write
---

# /kotak-export — Kotak Statement Export

Drives `netbanking.kotak.com/knb2/` via Playwright MCP and saves PDFs to a local path. The user relays the SMS+email OTP at login.

## Prerequisites

- **Playwright MCP** installed at user scope:
  `claude mcp add playwright -s user -- npx -y @playwright/mcp@latest`
  (then restart Claude Code so the `mcp__playwright__*` tools register)
- **1Password CLI** authed (`op vault list` works)
- A 1Password entry for Kotak with `username` (CRN) and `password` fields. Find it with:
  `op item list --vault Private --format json | jq '.[] | select(.title | test("kotak"; "i")) | .title'`

## Login flow

1. Pull creds:
   `op item get "<entry>" --vault Private --fields username --reveal`
   `op item get "<entry>" --vault Private --fields password --reveal`
2. `mcp__playwright__browser_navigate` to `https://netbanking.kotak.com/knb2/`
3. Fill CRN + password, click "Secure login"
4. **OTP screen**: before submitting, set the *"GO DIRECTLY TO HOME"* combobox to **"Statements"** so you land on the right page post-OTP and skip a navigation hop.
5. Ask the user for the OTP — it goes to the registered mobile + email.
6. Enter OTP, submit.

No re-OTP is required for statement downloads (good). But the browser session can die between tool calls and the page resets to `about:blank` — re-login is the only fix. Each login = one new OTP.

## Easy path: Annual Statements

The "Annual Account Statements" panel on the Statements page gives **one-click PDFs for current and previous FY**. Four `cursor-pointer` listitems:

- Download Financial Year (Current)
- Download Calendar Year (Current)
- Download Financial Year (Previous)
- Download Calendar Year (Previous)

Click → a popover with `<li class="list-format">` PDF/CSV options appears → click the visible "PDF" `<li>`.

## Older periods: Advanced Filters

Click the "Advanced filters" link at the bottom of the Annual Statements panel (or in Recent Transactions). A modal opens with From / To date pickers.

### Datepicker traps (worth ~10 turns of debugging)

Kotak uses ng-bootstrap's `ngbDatepicker`. Two non-obvious behaviours:

1. **Typed `value` on the date input is silently rejected.** Setting `input.value = "31/03/2024"` and dispatching `input`/`change` events appears to work but the form-control resets it. You **must** use the calendar widget.

2. **The To-picker, when reopened, shows TODAY's month — not From's month.** If you naively click "31" expecting March, you get `31/<current-month>/<current-year>`. Always navigate via the year/month `<select>` dropdowns first.

Reliable picker-driving snippet (run inside `mcp__playwright__browser_evaluate`):

```js
async () => {
  const inputs = () => [...document.querySelectorAll('input[placeholder="Select date"]')];
  const sels = () => [...document.querySelectorAll('select')].filter(s => s.offsetParent !== null);
  const pickDate = async (which /* 0=From, 1=To */, year, month /* 1-12 */, day) => {
    inputs()[which].click();
    await new Promise(r => setTimeout(r, 200));
    const ySel = sels().find(s => [...s.options].some(o => o.text === String(year)));
    const mSel = sels().find(s => [...s.options].some(o => o.text === 'Jan'));
    ySel.value = String(year); ySel.dispatchEvent(new Event('change', {bubbles:true}));
    mSel.value = String(month); mSel.dispatchEvent(new Event('change', {bubbles:true}));
    await new Promise(r => setTimeout(r, 200));
    [...document.querySelectorAll('div.ngb-dp-day')]
      .filter(c => !c.className.includes('disabled') && !c.className.includes('outside'))
      .find(c => c.textContent.trim() === String(day))
      .click();
  };
  await pickDate(0, 2024, 1, 1);   // From: 01/01/2024
  await pickDate(1, 2024, 3, 31);  // To:   31/03/2024
  return {from: inputs()[0].value, to: inputs()[1].value};
}
```

### Range cap

- **≤ 365 days** → Apply button enabled, direct download path.
- **> 365 days** → modal replaces Apply with "Receive by post" / "Receive by email" only. No direct PDF.
- **From auto-clamps** to the account-opening date — picking earlier silently snaps forward.

To back-fill multi-year history: split into ≤365-day chunks (e.g. one per calendar year + a tail). Combined with the Annual Statements panel covering current + previous FY, **2 Advanced Filter chunks per account** is usually enough for ~3 years of history.

## Download flow

After Apply, the Recent Transactions header shows a "Download" cursor-pointer. Click it →

1. Popover with **"Download Statement"** / "Receive by post" / "Receive by email"
2. Click "Download Statement" → format menu appears
3. Click the visible "PDF" `<li>` (not "CSV", "MT940", "MT950")

Files land in `<cwd>/.playwright-mcp/KM<id>_statement.pdf`. Move them:

```bash
mv "$PWD/.playwright-mcp/KM"*"_statement.pdf" \
   "$HOME/Downloads/kotak/<account>/<period-label>.pdf"
```

## Multi-account

If the CRN has multiple linked accounts, the Statements page has a savings-account `<select>`. Switch via:

```js
const sel = [...document.querySelectorAll('select')]
  .find(s => [...s.options].some(o => /Savings/i.test(o.text)));
sel.value = '<acct-id>';
sel.dispatchEvent(new Event('change', {bubbles:true}));
```

The page re-renders with the new account's data; no re-login needed.

## Gotchas reference

- `browser_evaluate` results truncate at ~200KB. Don't dump full DOM — query targeted selectors only.
- `browser_snapshot` element refs go stale fast on this Angular SPA. Prefer JS-based selection by text + className.
- Format-choice popovers (PDF/CSV/etc.) attach to the body, not the button — they survive re-renders. Match by `li.list-format` + visible.
- The login-page landing-page combobox saves a click later — set it before submitting OTP.
- Closing Balance figure on the filtered Recent Transactions view confirms the filter actually applied (vs. reset to single-day).
