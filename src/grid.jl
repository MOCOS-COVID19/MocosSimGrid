using CSV
using DataFrames
using DataStructures
using JSON
const Path = Vector{String}

function parserange(str::AbstractString)
  parts = split(str, ":")
  if 2 == length(parts)
    b = parse(Float64, parts[1])
    e = parse(Float64, parts[2])
    b:e
  elseif 3 == length(parts)
    b = parse(Float64, parts[1])
    s = parse(Float64, parts[2])
    e = parse(Float64, parts[3])
    b:s:e
  else
    nothing
  end
end

function findranges(dict::AbstractDict{String,T} where T)
  paths = Vector{Path}()
  for key in keys(dict)
    val = dict[key]
    if isa(val, AbstractString)
      if nothing != parserange(val)
        push!(paths, Path([key]))
      end
    elseif isa(val, AbstractDict)
      append!(paths, map(path->insert!(copy(path), 1, key), findranges(dict[key])))
    end
  end
  paths
end

getbypath(dict::AbstractDict{T} where T<:AbstractString, path::Path) = getbypath(dict[path[1]], path[2:end])
getbypath(val, ::Path) = val

function setbypath!(dict::AbstractDict{T} where T<:AbstractString, path::Path, value::Real)
  if length(path) > 1
    setbypath!(dict[path[1]], path[2:end], value)
  else
    dict[only(path)] = value
  end
end

make_job_script(cmd_dir, julia_path="julia", launcher_path="/home/tomoz/MocosSimLauncher/")="""
#!/bin/bash
set -Eeuxo pipefail

cd $cmd_dir

JOB_IDX=`expr \$PBS_ARRAY_INDEX + 1`
JOB_DIR=`tail -n+"\${JOB_IDX}" jobdirs.txt | head -n1`
cd "\${JOB_DIR}"

mkdir -p output

\\time -v $julia_path -O3 --threads 2 --project $launcher_path $(joinpath(launcher_path, "advanced_cli.jl"))"\\
  --output-summary  output/summary.jld2 \\
  1> "stdout.log" \\
  2> "stderr.log"

touch "_SUCCESS"
"""

function main()
  @assert length(ARGS) > 0 "JSON file needed"

  json = JSON.parsefile(ARGS[1], dicttype=OrderedDict)
  workdir = length(ARGS)>1 ? ARGS[2] : splitext(ARGS[1])[1]

  rangepaths = findranges(json) |> sort
  ranges = map(x->getbypath(json, x) |> parserange, rangepaths)

  @info "ranges are" rangepaths ranges

  @assert length(ranges) == 2 "we support only 2D grids now"
  xpath, ypath = rangepaths
  xrange, yrange = ranges

  df = DataFrame([String[], Float64[], Float64[]], [:path, Symbol(join(xpath, "_")), Symbol(join(ypath, "_"))])

  for (x,xval) in enumerate(xrange)
    for (y,yval) in enumerate(yrange)
      subdir = joinpath(workdir, "grid_$(x-1)_$(y-1)")
      mkpath(subdir)
      specific_json = deepcopy(json)
      setbypath!(specific_json, xpath, xval)
      setbypath!(specific_json, ypath, yval)

      open(joinpath(subdir, "params_experiment.json"),"w") do f
        JSON.print(f, specific_json)
      end
      push!(df, ("grid_$(x-1)_$(y-1)", xval, yval))
    end
  end
  CSV.write(joinpath(workdir, "parameters_map.csv"), df)
  CSV.write(joinpath(workdir, "jobdirs.txt"), select(df, :path), writeheader=false)

  @info "generated $(nrow(df)) jobs"

  open(joinpath(workdir, "template.json"),"w") do f
    JSON.print(f, json, 2)
  end

  write(joinpath(workdir, "script.sh"), make_job_script(abspath(workdir)))
  num_jobs = nrow(df)

  command = `qsub
    -J 0-$num_jobs
    -N Julia-Grid
    -l walltime=48:00:00
    -l select=1:ncpus=2:mem=8gb
    -q "covid-19"
    -o "stdout-main.log"
    -e "stderr-main.log"
    script.sh
  `

  @info "executing command" command
  run(command)

end

main()
