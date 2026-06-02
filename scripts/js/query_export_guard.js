/**
 * Query and export guard for ERP list pages.
 *
 * Scene:
 * Users may query or export a very large date range without selecting project,
 * department or organization. This can cause slow pages, huge export files and
 * unnecessary pressure on the back-end service.
 */

function parseDateValue(value) {
  if (!value) {
    return null;
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function diffDays(startDate, endDate) {
  const day = 24 * 60 * 60 * 1000;
  return Math.floor((endDate.getTime() - startDate.getTime()) / day);
}

function validateQueryRange(formData, options = {}) {
  const errors = [];
  const maxDays = options.maxDays || 31;
  const startDate = parseDateValue(formData.startDate);
  const endDate = parseDateValue(formData.endDate);

  if (!startDate || !endDate) {
    errors.push("请选择开始日期和结束日期");
  } else if (startDate > endDate) {
    errors.push("开始日期不能晚于结束日期");
  } else if (diffDays(startDate, endDate) > maxDays) {
    errors.push(`查询日期范围不能超过 ${maxDays} 天`);
  }

  (options.requiredFields || []).forEach((field) => {
    const value = formData[field.name];
    if (value === undefined || value === null || String(value).trim() === "") {
      errors.push(`${field.label || field.name}不能为空`);
    }
  });

  return {
    valid: errors.length === 0,
    errors
  };
}

function bindQueryGuard(formSelector, buttonSelector, collectFormData, options = {}) {
  const button = document.querySelector(buttonSelector);

  if (!button) {
    console.warn(`[ERP] Query button not found: ${buttonSelector}`);
    return;
  }

  button.addEventListener("click", (event) => {
    const formData = collectFormData(document.querySelector(formSelector));
    const result = validateQueryRange(formData, options);

    if (!result.valid) {
      event.preventDefault();
      alert(result.errors.join("\n"));
    }
  });
}

function confirmLargeExport(formData, options = {}) {
  const result = validateQueryRange(formData, {
    maxDays: options.maxDays || 31,
    requiredFields: options.requiredFields || []
  });

  if (!result.valid) {
    return {
      allowed: false,
      message: result.errors.join("\n")
    };
  }

  const estimateRows = Number(formData.estimateRows || 0);
  const threshold = options.confirmRows || 5000;

  if (estimateRows > threshold) {
    return {
      allowed: false,
      message: `预计导出 ${estimateRows} 行，超过建议阈值 ${threshold} 行，请缩小条件或分批导出`
    };
  }

  return {
    allowed: true,
    message: ""
  };
}

if (typeof window !== "undefined") {
  window.erpQueryExportGuard = {
    validateQueryRange,
    bindQueryGuard,
    confirmLargeExport
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    parseDateValue,
    diffDays,
    validateQueryRange,
    confirmLargeExport
  };
}
