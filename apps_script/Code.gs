// ====== CONFIGURATION ======
// This file is a reference copy only — the real one lives inside your
// Google Sheet under Extensions > Apps Script. Paste this there, not here.
var SHEET_NAME = 'Daily Record';
var SECRET = 'CHANGE_THIS_TO_YOUR_OWN_PRIVATE_WORD';

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);

    if (data.secret !== SECRET) {
      return jsonResponse({ status: 'error', message: 'Invalid secret' });
    }

    var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
    if (!sheet) {
      return jsonResponse({ status: 'error', message: 'Sheet not found' });
    }

    var timestamp = data.timestamp ? new Date(data.timestamp) : new Date();
    var monthName = Utilities.formatDate(timestamp, Session.getScriptTimeZone(), 'MMMM');

    // ---- Week separator check ----
    var lastRow = sheet.getLastRow();
    if (lastRow >= 2) {
      var existingTimestamp = sheet.getRange(2, 1).getValue();
      if (existingTimestamp instanceof Date && !isSameWeek(existingTimestamp, timestamp)) {
        sheet.insertRowBefore(2);
      }
    }

    // ---- Insert the new entry at the very top ----
    sheet.insertRowBefore(2);
    sheet.getRange(2, 1, 1, 5).setValues([[timestamp, monthName, data.category, Number(data.amount), data.notes || '']]);
    sheet.getRange(2, 1).setNumberFormat('hh:mm AM/PM');

    return jsonResponse({ status: 'success' });
  } catch (err) {
    return jsonResponse({ status: 'error', message: err.toString() });
  }
}

function isSameWeek(dateA, dateB) {
  return getMonday(dateA).getTime() === getMonday(dateB).getTime();
}

function getMonday(date) {
  var d = new Date(date);
  var day = d.getDay();
  var diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
