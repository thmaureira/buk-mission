module ApplicationHelper
  # 13.5 → "13,5 días"
  def days(value, precision: 1, unit: true)
    number = number_with_precision(value || 0, precision: precision, separator: ",", delimiter: ".")
    unit ? "#{number} días" : number
  end

  def signed_days(value)
    sign = value.positive? ? "+" : ""
    content_tag(:span, "#{sign}#{days(value, precision: 2, unit: false)}",
                class: value.positive? ? "num-pos" : "num-neg")
  end

  def fdate(date) = date ? l(date) : "—"
  def fdate_dash(date) = date ? l(date, format: :short) : "—"

  def nav_link(label, path, icon:, active: nil)
    active = current_page?(path) if active.nil?
    link_to path, class: ["nav-item", ("active" if active)] do
      content_tag(:span, icon, class: "nav-icon") + content_tag(:span, label)
    end
  end

  def badge(text, tone = "neutral") = content_tag(:span, text, class: "badge badge-#{tone}")

  def status_badge(period, date = Date.current)
    tone = { "taken" => "success", "requested" => "info", "cancelled" => "muted" }[period.status_on(date)]
    badge(period.status_label(date), tone)
  end

  def kind_badge(entry)
    tone = { "grant" => "success", "usage" => "info", "expiration" => "warning",
             "adjustment" => "purple", "reversal" => "muted" }[entry.kind]
    badge(entry.kind_label, tone)
  end

  def card(title, open: true, actions: nil, id: nil, &block)
    content_tag(:details, class: "card", open: open, id: id) do
      content_tag(:summary, class: "card-header") do
        content_tag(:h2, title) + content_tag(:span, "", class: "chevron")
      end + content_tag(:div, class: "card-body") do
        (actions ? content_tag(:div, actions, class: "card-actions") : "".html_safe) + capture(&block)
      end
    end
  end
end
