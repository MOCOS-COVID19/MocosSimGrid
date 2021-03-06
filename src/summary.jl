using Distributed

using CSV
using DataFrames
@everywhere using FileIO
using JLD2
using ProgressMeter
using Statistics

@assert length(ARGS) >= 1 "no experiment path given"

prefix_path = ARGS[1]
num_trajectories = length(ARGS)==2 ? parse(Int, ARGS[2]) : 1000

df = CSV.read(joinpath(prefix_path, "parameters_map.csv"), DataFrame)
output_dirs = map( x-> joinpath(prefix_path, x, "output"), df.path)
nans = fill(NaN, num_trajectories)

results = @showprogress pmap(output_dirs) do path
  try
    load(joinpath(path, "summary.jld2"), "last_infections", "num_infections", "peak_daily_detections", "peak_daily_infections")
  catch e
    @warn "could not load summary" path
    nans, nans, nans, nans
  end
end

last_infections = getindex.(results, 1)
num_infections = getindex.(results, 2)
peak_daily_detections = getindex.(results, 3)
peak_daily_infections = getindex.(results, 4)

df.mean_last_infection_time = last_infections .|> mean
df.mean_num_infected = num_infections .|> mean
df.peak_daily_detections = peak_daily_detections .|> mean
df.peak_daily_infections = peak_daily_infections .|> mean

save(joinpath(prefix_path,"summary.jld2"),
  "summary", df,
  "last_infections", last_infections,
  "num_infections", num_infections,
  "peak_daily_detections", peak_daily_detections,
  "peak_daily_infections", peak_daily_infections,
  compress=true
)

save(joinpath(prefix_path,"summary.csv"), df)