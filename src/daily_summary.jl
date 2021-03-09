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

df = CSV.read(joinpath(prefix_path, "parameters_map.csv")) |> DataFrame

output_path = joinpath(prefix_path,"all_daily.jld2")

jldopen(output_path, "w", compress=true) do outfile
  @showprogress for row in eachrow(df)
    outgroup = JLD2.Group(outfile, row.path)
    jldopen(joinpath(prefix_path, row.path, "daily.jld2")) do infile
      for key in parse.(Int,keys(infile)) |> sort
        ingroup = infile[key]
        outgroup2 = JLD2.Group(outgroup, key)
        outgroup2["daily_infections"] = ingroup["daily_infections"]
        outgroup2["daily_detections"] = ingroup["daily_detections"]
      end
    end
  end
end
