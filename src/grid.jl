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

make_job_script(;
  cmd_dir::AbstractString,
  image_path::AbstractString,
  julia_path::AbstractString="julia",
  num_threads::Integer=1,
  )="""
#!/bin/bash
set -Eeuxo pipefail

cd $cmd_dir

JOB_IDX=`expr \$PBS_ARRAY_INDEX + 1`
JOB_DIR=`head -n "\${JOB_IDX}" jobdirs.txt | tail -n1`
cd "\${JOB_DIR}"

test -f _SUCCESS && exit 0

mkdir -p output

$julia_path -O3 --threads $num_threads -J $image_path \\
  -e 'MocosSimLauncher.launch(["params_experiment.json", "--output-summary", "output/summary.jld2"])' \\
  1> stdout.log \\
  2> stderr.log \\
  &

JULIA_PID=\$!
echo JULIA_PID=\$JULIA_PID
pidstat -r -p \$JULIA_PID 1 > memory.log &
pidstat -u -p \$JULIA_PID 1 > cpu.log &

wait \$JULIA_PID && touch _SUCCESS && exit 0


"""

function main()
  @assert length(ARGS) > 0 "JSON file needed"

  json = JSON.parsefile(ARGS[1], dicttype=OrderedDict)
  memory_gb = length(ARGS) > 1 ? ARGS[2] : 16
  num_threads = length(ARGS) > 2 ? ARGS[3] : 1
  workdir = length(ARGS) > 3 ? ARGS[4] : splitext(ARGS[1])[1]
  launcher_path = length(ARGS) > 4 ? ARGS[5] : "/home/tomoz/MocosSimLauncher/"

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

  script = make_job_script(cmd_dir=abspath(workdir), image_path=joinpath(launcher_path, "sysimage.img"), num_threads=num_threads)
  write(joinpath(workdir, "script.sh"), script)
  num_jobs = nrow(df)

 

  cd(workdir)
  mkpath("task-logs")
  cd("task-logs")

  command = `qsub
    -J 0-$num_jobs
    -N "JG"
    -l walltime=48:00:00
    -l select=1:ncpus=$(num_threads):mem=$(memory_gb)gb
    -q "covid-19"
    ../script.sh
  `

  @info "executing command" command
  run(command)

end

main()
