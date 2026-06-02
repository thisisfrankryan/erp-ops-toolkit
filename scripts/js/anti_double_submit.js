/**
 * ERP front-end duplicate submit protection.
 *
 * Scene:
 * Users may repeatedly click "Submit" while the network is slow, causing
 * duplicate requests, repeated documents, or inconsistent order states.
 *
 * Usage:
 *   bindSubmitProtection("#submitButton", async () => {
 *     // await submitForm();
 *   });
 */
function bindSubmitProtection(buttonSelector, submitHandler, options = {}) {
  const button = document.querySelector(buttonSelector);
  if (!button) {
    console.warn(`[ERP] Submit button not found: ${buttonSelector}`);
    return;
  }

  const submittingText = options.submittingText || "正在提交，请稍候...";
  const recoverOnError = options.recoverOnError !== false;
  const originalText = button.innerText;

  button.addEventListener("click", async function handleClick(event) {
    event.preventDefault();

    if (button.dataset.submitting === "true") {
      return;
    }

    button.dataset.submitting = "true";
    button.disabled = true;
    button.innerText = submittingText;

    try {
      await submitHandler(event);
    } catch (error) {
      console.error("[ERP] Submit failed:", error);

      if (recoverOnError) {
        button.dataset.submitting = "false";
        button.disabled = false;
        button.innerText = originalText;
      }
    }
  });
}

// Browser global export for legacy ERP pages.
if (typeof window !== "undefined") {
  window.bindSubmitProtection = bindSubmitProtection;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { bindSubmitProtection };
}
