---
name: ufile-slips
description: Automates managing (adding, filling, exporting, and deleting) T3 and T5 tax slips in UFile via the browser. Use this skill whenever the user mentions adding, filling, exporting, deleting, or managing T3 or T5 tax slips in UFile.
---

# UFile Slips Management

This skill enables agents to manage (Add, Fill, Export, and Delete) T3 and T5 tax slips in UFile using bundled JavaScript automation scripts executed in the browser context.

## Prerequisites

### Browser & Remote Debugging

- **Chrome Browser**: Must use Google Chrome (not Edge, Safari, or other browsers).
- **Enable Remote Debugging**: 
  1. Open Chrome and navigate to `chrome://inspect/#remote-debugging`
  2. Check the "Allow remote debugging for this browser instance" checkbox
  3. Keep the Chrome window open while using this skill

### Chrome DevTools MCP Setup

- **Install Chrome DevTools MCP**:
  ```bash
  npm install -g @anthropic-ai/chrome-devtools-mcp
  ```

- **Configure Your Agent**: Add the Chrome DevTools MCP to your agent's MCP configuration. See [Chrome DevTools MCP Setup Guide](https://developer.chrome.com/blog/chrome-devtools-mcp-debug-your-browser-session) for detailed configuration instructions.

### UFile Setup

- **Active UFile Tab**: Must have an active UFile interview page loaded in Chrome (normally under `https://secure.ufile.ca/...`).
- The agent will use Chrome DevTools MCP tools (`evaluate_script`, `take_snapshot`, etc.) to interact with the page.

## Core Workflow

### 1. Active Page Check
Before executing any script, ensure the active browser tab is the UFile interview page. If it is not:
1. Call `list_pages` to list all tabs.
2. Search for a page with URL matching `secure.ufile.ca`.
3. Switch context to it using `select_page`.

---

## Operations & Script Usage

The skill bundles four JS automation scripts in its `scripts/` directory. For all operations, execute the script contents followed by the function call via `evaluate_script` (or other script execution tools).

### 1. Adding a Slip (`add_slip.js`)

**Purpose**: Adds a new T3 or T5 slip. It will click the appropriate left menu item and click the "Add Item" button on the summary page.
- **Function**: `addSlip(type)`
- **Parameters**: `type` - `"T3"` or `"T5"` (case-insensitive).
- **Usage Example**:
  ```javascript
  // Load add_slip.js content and append:
  await addSlip("T3"); // Or "T5"
  ```

### 2. Filling a Slip (`fill_slip.js`)

**Purpose**: Fills fields in the currently active slip form page. It matches labels automatically.
- **Function**: `fillSlip(data)`
- **Parameters**: `data` - an object mapping keys to field values.
- **Supported Fields**:
  - `issuer`: Name of issuer / Trust name (e.g. `"CIBC"`, `"RBC"`)
  - `box21`: Capital gains
  - `box26`: Other income
  - `box42`: Cost base adjustment
  - `box13`: Interest
  - `box14`: Other income (T5)
  - `box15`: Foreign income
  - `box24`: Actual amount of eligible dividends (T5)
- **Usage Example**:
  ```javascript
  // Load fill_slip.js content and append:
  await fillSlip({
    issuer: "CIBC",
    box42: "1500.00",
    box21: "250.00",
    box26: "100.00"
  });
  ```

### 3. Exporting a Slip (`export_slip.js`)

**Purpose**: Extracts the filled values from the currently active slip form page.
- **Function**: `exportSlip()`
- **Return Value**: A string in the format: `[Type] [Issuer] [Box1]:[Value1], [Box2]:[Value2], ...`
- **Usage Example**:
  ```javascript
  // Load export_slip.js content and append:
  exportSlip();
  // Returns: "T3 CIBC 21:250.00, 26:100.00, 42:1500.00"
  ```
- **Batch Export**: If exporting multiple slips, navigate to each slip page (using left menu links) and execute `exportSlip()` on each page.

### 4. Deleting Slips (`delete_slips.js`)

**Purpose**: Deletes slips. Must be executed while on the summary page ("Interest, investment income and carrying charges").
- **Function**: `deleteSlips(typeOrNames)`
- **Parameters**:
  - `typeOrNames`: string (e.g., `"T3"` to delete all T3 slips) or string array (e.g., `["T3: CIBC", "T5: RBC"]` to delete specific ones).
- **Usage Example**:
  ```javascript
  // Load delete_slips.js content and append:
  await deleteSlips("T3"); // Deletes all T3 slips
  await deleteSlips(["T5: RBC"]); // Deletes only T5 RBC
  ```
