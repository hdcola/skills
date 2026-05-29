/**
 * export_slip.js
 * 
 * 这个脚本用于从当前的 UFile 凭单录入页面提取数据并生成简练的文本格式。
 * 格式示例: T5 BMO Bank 13:250.00, 14:100.00, 15:400.00
 */

function exportSlip() {
  const isT3 = document.body.innerText.includes("T3 - Statement of Trust income");
  const isT5 = document.body.innerText.includes("T5 - Statement of Investment income");
  const type = isT3 ? "T3" : (isT5 ? "T5" : "Unknown");

  if (type === "Unknown") {
    console.error("❌ 错误: 未能在当前页面识别出 T3 或 T5 表单。");
    return "Error: Not on a T3/T5 page";
  }

  // 1. 获取颁发机构 (Issuer)
  const issuerInput = Array.from(document.querySelectorAll('input, textbox, [role="textbox"]'))
    .find(el => (el.getAttribute('aria-label') || '').toLowerCase().includes("issued by"));
  const issuer = issuerInput ? issuerInput.value.trim() : "Unknown Issuer";

  // 2. 遍历所有输入框，寻找带 Box 编号的字段
  const boxes = [];
  const inputs = Array.from(document.querySelectorAll('input:not([type="hidden"]), [role="textbox"]'));

  inputs.forEach(input => {
    let val = (input.value || input.innerText || "").trim();

    // 清理金额格式（移除 $, 逗号, 空格）
    const numericStr = val.replace(/[$,\s]/g, '');
    if (!numericStr || numericStr === "0.00" || isNaN(numericStr)) return;

    const label = (input.getAttribute('aria-label') || '').toLowerCase();
    
    // 排除非金额 Box 字段
    if (label.includes("issued by") || 
        label.includes("percentage") || 
        label.includes("country name") || 
        label.includes("exchange rate")) return;

    // 尝试从标签中提取 Box 编号
    let boxMatch = label.match(/box\s*(\d+)/i) || label.match(/(\d+)/);
    let boxNum = boxMatch ? boxMatch[1] : null;

    // 如果 aria-label 没找到 (常见于 T3)，尝试在前面的元素中寻找
    if (!boxNum) {
      let prev = input.parentElement;
      for (let i = 0; i < 5; i++) { // 向上查找几层并搜索兄弟节点
        if (!prev) break;
        const text = prev.innerText || "";
        const m = text.match(/box\s*(\d+)/i) || text.match(/(\d+)/);
        if (m) {
          boxNum = m[1];
          break;
        }
        prev = prev.previousElementSibling || prev.parentElement;
      }
    }
    
    if (boxNum) {
      boxes.push(`${boxNum}:${numericStr}`);
    }
  });

  // 3. 去重并按 Box 编号排序
  const uniqueBoxes = [...new Set(boxes)].sort((a, b) => {
    return parseInt(a.split(':')[0]) - parseInt(b.split(':')[0]);
  });

  // 4. 组合结果
  const result = `${type} ${issuer} ${uniqueBoxes.join(", ")}`;
  console.log("📋 导出结果:");
  console.log(result);
  return result;
}

// 执行
exportSlip();
