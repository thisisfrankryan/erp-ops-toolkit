/**
 * Front-end error recorder for ERP support.
 *
 * Scene:
 * Users often report "page is blank" or "button has no response" without clear
 * screenshots. This helper records JavaScript errors, unhandled promise errors
 * and failed fetch requests so support engineers can collect useful evidence.
 */

function createErrorRecord(type, detail = {}) {
  return {
    type,
    pageUrl: typeof location !== "undefined" ? location.href : "",
    userAgent: typeof navigator !== "undefined" ? navigator.userAgent : "",
    occurredAt: new Date().toISOString(),
    ...detail
  };
}

function saveErrorRecord(record, options = {}) {
  const storageKey = options.storageKey || "erp_frontend_error_records";
  const maxRecords = options.maxRecords || 20;

  try {
    const records = JSON.parse(localStorage.getItem(storageKey) || "[]");
    records.unshift(record);
    localStorage.setItem(storageKey, JSON.stringify(records.slice(0, maxRecords)));
  } catch (error) {
    console.warn("[ERP] Failed to save error record:", error);
  }

  if (typeof options.reporter === "function") {
    options.reporter(record);
  }
}

function bindWindowErrorRecorder(options = {}) {
  window.addEventListener("error", (event) => {
    saveErrorRecord(createErrorRecord("javascript_error", {
      message: event.message,
      source: event.filename,
      line: event.lineno,
      column: event.colno,
      stack: event.error && event.error.stack
    }), options);
  });

  window.addEventListener("unhandledrejection", (event) => {
    const reason = event.reason || {};
    saveErrorRecord(createErrorRecord("unhandled_promise", {
      message: reason.message || String(reason),
      stack: reason.stack
    }), options);
  });
}

function bindFetchErrorRecorder(options = {}) {
  if (typeof window === "undefined" || typeof window.fetch !== "function") {
    return;
  }

  const originalFetch = window.fetch.bind(window);

  window.fetch = async function recordFetchError(input, init) {
    const requestUrl = typeof input === "string" ? input : input && input.url;
    const method = (init && init.method) || "GET";

    try {
      const response = await originalFetch(input, init);

      if (!response.ok) {
        saveErrorRecord(createErrorRecord("http_error", {
          requestUrl,
          method,
          status: response.status,
          statusText: response.statusText
        }), options);
      }

      return response;
    } catch (error) {
      saveErrorRecord(createErrorRecord("network_error", {
        requestUrl,
        method,
        message: error.message,
        stack: error.stack
      }), options);
      throw error;
    }
  };
}

function exportErrorRecords(storageKey = "erp_frontend_error_records") {
  try {
    return JSON.parse(localStorage.getItem(storageKey) || "[]");
  } catch (error) {
    console.warn("[ERP] Failed to export error records:", error);
    return [];
  }
}

function bindAppErrorRecorder(options = {}) {
  bindWindowErrorRecorder(options);
  bindFetchErrorRecorder(options);
}

if (typeof window !== "undefined") {
  window.erpAppErrorRecorder = {
    bindAppErrorRecorder,
    exportErrorRecords,
    saveErrorRecord
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    createErrorRecord,
    saveErrorRecord,
    exportErrorRecords
  };
}
