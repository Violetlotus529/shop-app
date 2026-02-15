document.addEventListener("DOMContentLoaded", () => {
  const tbody = document.getElementById("inventories-body")
  if (!tbody) return

  const saveBtn = document.getElementById("save-inventories")
  const form = document.getElementById("inventory-filters")
  const paginationEl = document.getElementById("pagination")

  function renderRows(variants) {
    tbody.innerHTML = ""
    variants.forEach(v => {
      const tr = document.createElement("tr")
      tr.innerHTML = `
        <td>${v.product_name}</td>
        <td>${v.color}</td>
        <td>${v.size}</td>
        <td>
          <input
            type="number"
            value="${v.stock}"
            data-variant-id="${v.id}"
            data-original-stock="${v.stock}"
            min="0"
          >
        </td>
      `
      tbody.appendChild(tr)
    })
  }

  function confirmDiscardIfDirty() {
    const dirty = collectUpdates().length > 0
    if (!dirty) return true
    return confirm("未保存の変更があります。破棄して移動しますか？")
  }

  function renderPagination(pagination, currentParams) {
    if (!paginationEl) return
    const { current_page, total_pages } = pagination
    paginationEl.innerHTML = ""
    if (total_pages <= 1) return

    const prev = document.createElement("button")
    prev.type = "button"
    prev.textContent = "Prev"
    prev.disabled = current_page <= 1
    prev.addEventListener("click", () => {
      if (!confirmDiscardIfDirty()) return

      currentParams.set("page", String(current_page - 1))
      loadInventories(currentParams)
    })

    const next = document.createElement("button")
    next.type = "button"
    next.textContent = "Next"
    next.disabled = current_page >= total_pages
    next.addEventListener("click", () => {
      if (!confirmDiscardIfDirty()) return

      currentParams.set("page", String(current_page + 1))
      loadInventories(currentParams)
    })

    const info = document.createElement("span")
    info.textContent = ` Page ${current_page} / ${total_pages} `

    paginationEl.appendChild(prev)
    paginationEl.appendChild(info)
    paginationEl.appendChild(next)
  }

  async function loadInventories(params) {
    const qs = params.toString()
    const url = `/admin/api/inventories${qs ? `?${qs}` : ""}`

    const res = await fetch(url)
    const data = await res.json()

    renderRows(data.variants)
    if (data.pagination) renderPagination(data.pagination, params)

    history.replaceState(null, "", `${location.pathname}${qs ? `?${qs}` : ""}`)
  }

  function collectUpdates() {
    const updates = []
    const inputs = tbody.querySelectorAll("input[data-variant-id]")

    inputs.forEach(input => {
      const original = input.dataset.originalStock
      const current = input.value
      if (original !== current) {
        updates.push({ id: input.dataset.variantId, stock: current })
      }
    })

    return updates
  }

  if (form) {
    form.addEventListener("submit", (e) => {
      e.preventDefault()
      if (!confirmDiscardIfDirty()) return

      const params = new URLSearchParams(new FormData(form))
      params.set("page", "1")
      loadInventories(params)
    })
  }

  if (saveBtn) {
    saveBtn.addEventListener("click", async () => {
      const updates = collectUpdates()

      if (updates.length === 0) {
        alert("変更はありません")
        return
      }

      try {
        const res = await fetch("/admin/api/inventories/bulk_update", {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ updates })
        })

        const json = await res.json().catch(() => ({}))
        if (!res.ok) throw json

        // 保存成功後、original を更新して「変更検知」をリセット
        const inputs = tbody.querySelectorAll("input[data-variant-id]")
        inputs.forEach(input => { input.dataset.originalStock = input.value })

        alert(`更新件数: ${json.updated_count}`)
      } catch (err) {
        alert(err.message || err.error || "保存に失敗しました")
      }
    })
  }
  
  function syncFormFromQuery(params) {
    if (!form) return
    for (const [key, value] of params.entries()) {
      const el = form.querySelector(`[name="${CSS.escape(key)}"]`)
      if (el) el.value = value
    }
  }

  const initialParams = new URLSearchParams(location.search)
  syncFormFromQuery(initialParams)
  loadInventories(initialParams)
})
