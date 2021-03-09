using PyPlot
using FileIO

mystep(r::AbstractRange) = step(r)
mystep(r::AbstractArray) = r[2] - r[1]

extendrange(r) = range( (first(r)-mystep(r)/2), last(r)+mystep(r)/2, length=length(r)+1)

function plot_heatmap_tracing_prob_vs_c(
  results,
  tracing_probs = 0:0.05:1,
  Cs=0:0.05:1;
  cmin=nothing,
  cmax=nothing,
  logscale=true,
  addcbar::Bool=true,
  polish::Bool=false)

  reduction = 1 .- Cs / 1.35  |> collect

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    img = pcolor(
      extendrange(reduction),
      extendrange(tracing_probs),
      results,
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    img = pcolor(
      extendrange(reduction),
      extendrange(tracing_probs),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end

  if addcbar
    cbar = colorbar()
  end

  if polish
    xlabel("f - Stopień redukcji kontaktów")
    ylabel("b - skuteczność śledzenia kontaktów")
  else
    xlabel("f - contact reduction rate")
    ylabel("b - contact tracing efficiency")
  end

  xticks(
    0:0.1:1,
    ["$(100*f)%" for f in 0:0.1:1],
    rotation=60
  )

  gca().invert_yaxis()
  gca().invert_xaxis()
  img
end


function plot_heatmap_mild_detection_vs_tracing_prob(
    results,
    mild_detections::AbstractVector{T} where T <: Real = 0:0.05:1,
    tracking_probs::AbstractVector{T} where T <: Real = 0:0.05:1;
    cmin=nothing,
    cmax=nothing,
    logscale=true,
    addcbar=true,
    polish::Bool=false
  )

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    im = pcolor(
      extendrange(mild_detections),
      extendrange(tracking_probs),
      results,
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    im = pcolor(
      extendrange(mild_detections),
      extendrange(tracking_probs),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end

  clim(vmin=cmin)
  if addcbar
    colorbar()
  end

  gca().invert_yaxis()
  gca().invert_xaxis()
  if polish
    xlabel("q' - prawdopodobieństwo wykrycia lekkich przypadków")
    ylabel("b - skuteczność śledzenia kontaktów")
  else
    xlabel("q' - mild case detection probability")
    ylabel("b - contact tracing efficiency")
  end
  im
end

function plot_heatmap_mild_detection_vs_c(
    results,
    mild_detection_probs::AbstractVector{T} where T<:Real = 0:0.05:1,
    Cs::AbstractVector{T} where T <:Real=0:0.05:1;
    cmin=nothing, cmax=nothing,
    logscale::Bool=true,
    addcbar::Bool=true,
    polish::Bool=true)
  reduction = 1 .- Cs / 1.35  |> collect

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    im = pcolor(
      extendrange(reduction),
      extendrange(mild_detection_probs),
      results,
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    im = pcolor(
      extendrange(reduction),
      extendrange(mild_detection_probs),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end
  if addcbar
    c = colorbar()
  end

  gca().invert_yaxis()
  gca().invert_xaxis()

  if polish
    xlabel("f - Stopień redukcji kontaktów")
    ylabel("q' - Skuteczność wykrywania lekkich przypadków")
  else
    xlabel("f - contact reduction rate")
    ylabel("q' - mild case detection probability")
  end

  xticks(
    0:0.1:1,
    ["$(Int(100*f))%" for f in 0:0.1:1],
    rotation=60)

  im
end


function plot_heatmap_c_vs_phone_tracing_usage(results, Cs=0:0.05:1, phone_tracking_usage = 0:0.05:1; tlim=0.0001, cmin=nothing, cmax=nothing, logscale=true, addcbar::Bool=true, polish::Bool=false)
  reduction = 1 .- Cs / 1.35

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    im = pcolor(
      extendrange(reduction),
      extendrange(phone_tracking_usage),
      results,
      #norm=matplotlib.colors.SymLogNorm(linthresh=tlim, vmin=cmin, vmax=cmax),
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    im = pcolor(
      extendrange(reduction),
      extendrange(phone_tracking_usage),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end

  if addcbar
    cbar = colorbar()
  end

  if polish
    xlabel("f - Stopień redukcji kontaktów")
    ylabel("u - część populacji używająca aplikacji \n do śledzenia kontaktów")
  else
    xlabel("f - contact reduction rate")
    ylabel("u - fraction of population \n using the contact tracing app")
  end

  xticks(
    0:0.1:1,
    ["$(Int(100*f))%" for f in 0:0.1:1],
    rotation=60)

  gca().invert_yaxis()
  gca().invert_xaxis()

  return im
end

function plot_heatmap_phone_tracking_usage_vs_tracking_prob(
  results,
  phone_tracking_usages = 0:0.05:1,
  tracking_probs=0:0.05:1;
  cmin=nothing,
  cmax=nothing,
  logscale=true,
  addcbar=true
)

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    im = pcolor(
      extendrange(phone_tracking_usages),
      extendrange(tracking_probs),
      results,
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    im = pcolor(
      extendrange(phone_tracking_usages),
      extendrange(tracking_probs),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end

  clim(vmin=cmin)

  if addcbar
    colorbar()
  end

  gca().invert_xaxis()
  gca().invert_yaxis()
  xlabel("u - część populacji używająca aplikacji śledzącej")
  ylabel("b - skuteczność śledzenia kontaktów")
  return im
end

function plot_initiators_vs_c(results, initiators = 0:2:50, Cs=0:0.05:1; cmin=nothing, cmax=nothing, logscale=true, addcbar::Bool=true, polish::Bool=false)
  #figure(figsize=(10,5))
  reduction = 1 .- Cs / 1.35  |> collect

  if nothing == cmax
    cmax = maximum(results)
  end

  if nothing == cmin
    cmin = minimum(results)
  end

  if logscale
    img = pcolor(
      extendrange(reduction),
      extendrange(initiators),
      results,
      norm=matplotlib.colors.LogNorm(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
      clim(vmin=cmin)
  else
    img = pcolor(
      extendrange(reduction),
      extendrange(initiators),
      results,
      norm=matplotlib.colors.Normalize(vmin=cmin, vmax=cmax),
      cmap="nipy_spectral")
  end

  if addcbar
    cbar = colorbar()
  end

  if polish
    xlabel("f - stopień redukcji kontaktów")
    ylabel("n - liczba początkowych zarażeń")
  else
    xlabel("f - contact reduction rate")
    ylabel("n - number of initiators")
  end

  xticks(
    0:0.1:1,
    ["$(100*f)%" for f in 0:0.1:1],
    rotation=60
  )

  #gca().invert_yaxis()
  gca().invert_xaxis()
  img
end