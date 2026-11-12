module ImportsHelper
  # Coloured label showing an import's status.
  def status_badge(import)
    if import.status == "completed"
      colour = "success"
    elsif import.status == "failed"
      colour = "danger"
    else
      colour = "secondary"
    end

    tag.span(import.status, class: "badge text-bg-#{colour}")
  end
end
