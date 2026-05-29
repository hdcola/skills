/**
 * fill_slip.js
 * 
 * 通用脚本，用于在当前的 T3 或 T5 表单页录入数据。
 * 它会根据页面上的文本标签自动匹配输入框。
 */

async function fillSlip(data) {
  const isT3 = document.body.innerText.includes("T3 - Statement of Trust income");
  const isT5 = document.body.innerText.includes("T5 - Statement of Investment income");
  const type = isT3 ? "T3" : (isT5 ? "T5" : "Unknown");

  console.log(`🚀 开始录入 ${type} 数据...`);

  if (type === "Unknown") {
    console.error("❌ 错误: 未能在当前页面识别出 T3 或 T5 表单。");
    return { success: false, message: "Not on a T3 or T5 page" };
  }

  const findInput = (keywords) => {
    const inputs = Array.from(document.querySelectorAll('input, textbox'));
    // 尝试匹配所有关键词
    let found = inputs.find(el => {
      const label = (el.getAttribute('aria-label') || '').toLowerCase();
      return keywords.every(kw => label.includes(kw.toLowerCase()));
    });
    
    // 如果失败，尝试只匹配描述性关键词（排除纯数字）
    if (!found) {
      const descriptiveKeywords = keywords.filter(kw => isNaN(kw));
      if (descriptiveKeywords.length > 0) {
        found = inputs.find(el => {
          const label = (el.getAttribute('aria-label') || '').toLowerCase();
          return descriptiveKeywords.every(kw => label.includes(kw.toLowerCase()));
        });
      }
    }
    return found;
  };

  const fieldMap = {
    issuer: ["issued by"],
    // T3 / T5 通用或专用匹配
    box21: ["21", "capital gains"],
    box26: ["26", "other income"],
    box42: ["42", "cost base adjustment"],
    box13: ["13", "interest"],
    box14: ["14", "other income"],
    box15: ["15", "foreign income"]
  };

  const setValue = (el, val) => {
    if (el && val !== undefined) {
      el.focus();
      el.value = val;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.dispatchEvent(new Event('blur', { bubbles: true }));
    }
  };

  for (const [key, val] of Object.entries(data)) {
    const keywords = fieldMap[key] || [key];
    const input = findInput(keywords);
    if (input) {
      setValue(input, val);
      console.log(`✅ 已录入 ${key}: ${val}`);
    } else {
      console.warn(`⚠️ 未找到字段: ${key} (关键词: ${keywords})`);
    }
  }

  console.log(`✨ ${type} 数据录入任务完成。`);
  return { success: true, type, data };
}
