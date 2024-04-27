using CSV, Plots, LaTeXStrings, Optimization, OptimizationOptimJL, NativeFileDialog

files = pick_multi_file(filterlist="csv;CSV")
# files = ["/home/Timon/Documents/elektronik/c-tester-jl/messungen/SDS00001.csv"]

function objective(params, inputdata)
    t = inputdata.Second
    U = inputdata.Value

    start = findFirstNonzero(U)
    # println(start)

    t = t[start:end]
    U = U[start:end]

    ft = fit(t, params)

    return (sum((ft .- U) .^ 2))
end

function fit(t, params)
    U0, tau, t0 = params
    return U0 .* (1 .- exp.(-(t .- t0) ./ tau))
end

function findFirstNonzero(voltageData)
    i::UInt16 = 1
    while (voltageData[i] < 0.1)
        i += 1
    end
    return i
end

for f in files
    data = CSV.File(f; header=12)

    # data.Second = data.Second[500:end]
    # data.Value = data.Value[500:end]

    initialParams = [9, 1e-6, 0]

    problem = OptimizationProblem(objective, initialParams, data)
    optSolution = solve(problem, NelderMead())

    println(optSolution.u)

    p = plot(data.Second, data.Value,
        seriestype=scatter,
        label="Messwerte",
        title=f[end-4-3:end-4],
        xlabel=L"t" * " in " * L"s",
        ylabel=L"U" * " in " * L"V")

    y = fit(data.Second, optSolution.u)

    plot!(p, data.Second, y,
        label="fit")

    Plots.pdf(p, "out/"*f[end-4-3:end-4])
end