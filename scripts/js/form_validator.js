/**
 * ERP form validation helpers.
 *
 * Scene:
 * Business users may miss required fields or enter invalid amount/quantity
 * values. Basic front-end validation can reduce invalid requests before they
 * reach the back-end service.
 */
function validateRequired(value, fieldName) {
  if (value === undefined || value === null || String(value).trim() === "") {
    return `${fieldName}不能为空`;
  }
  return "";
}

function validatePositiveNumber(value, fieldName) {
  const requiredError = validateRequired(value, fieldName);
  if (requiredError) {
    return requiredError;
  }

  const numberValue = Number(value);
  if (!Number.isFinite(numberValue) || numberValue <= 0) {
    return `${fieldName}必须为大于 0 的数字`;
  }

  return "";
}

function validateErpForm(formData) {
  const errors = [];

  const amountError = validatePositiveNumber(formData.amount, "金额");
  if (amountError) {
    errors.push(amountError);
  }

  const supplierError = validateRequired(formData.supplierName, "供应商");
  if (supplierError) {
    errors.push(supplierError);
  }

  const documentDateError = validateRequired(formData.documentDate, "单据日期");
  if (documentDateError) {
    errors.push(documentDateError);
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

// Example:
// const result = validateErpForm({
//   amount: document.querySelector("#amountInput").value,
//   supplierName: document.querySelector("#supplierName").value,
//   documentDate: document.querySelector("#documentDate").value
// });
// if (!result.valid) alert(result.errors.join("\n"));

window.validateErpForm = validateErpForm;
