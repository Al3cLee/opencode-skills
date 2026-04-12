---
name: julia-datafitting
description: This skill should be used when working with Julia for data analysis tasks involving CSV file reading, curve fitting (linear and nonlinear), and plotting with CairoMakie. It covers the full Julia scientific computing workflow for physics experiments.
---

# Julia Datafitting

## Overview

Enable data extraction, fitting, and plotting workflows using the Julia toolchain. This skill covers reading CSV files into DataFrames, fitting data to linear and nonlinear models using CurveFit.jl, and creating publication-quality plots with CairoMakie.jl.

## Reading CSV Files

Read CSV files into a DataFrame using CSV.jl and access columns by their header names:

```julia
using CSV, DataFrames

experiment = DataFrame(CSV.File("data.csv"))

# Access columns by header name (trailing spaces after comma may cause issues)
x = experiment."f / Hz"
y = experiment."Vpp / Volt"
```

If all elements from the second row onward are numeric, the returned values automatically become float-valued vectors.

## Nonlinear Curve Fitting

Fit data to nonlinear functions using CurveFit.jl:

```julia
using CSV, DataFrames
using CurveFit

u = [zeros(2)]  # initialize parameter array

# Define fitting target function
# u and x are POSITIONAL arguments
fn(u, x) = @. u[1] / ((1 + 4 * pi^2 * x^2 * u[2]^2)^(0.5))

# Initial parameters
u0 = [0.5, 0.015]

# Generate sample data
experiment = DataFrame(CSV.File("experiment/f-V.csv"))

x = experiment."f / Hz"
y = experiment."Vpp / Volt"

# Create problem with initial guess for parameters
prob = NonlinearCurveFitProblem(fn, u0, x, y)
sol = solve(prob)

# Optionally produce related data
mean_sq_err = mse(sol)
conf_int = confint(sol)

println("Fitted parameters: ", sol.u)
println("mean square error: ", mean_sq_err)
println("confidence interval of 95%: ", conf_int)
```

## Linear Fitting

Fit data to linear functions using CurveFit.jl:

```julia
using CurveFit

# Generate sample data: y = 2.5 * x + 3.0
x = collect(0:0.1:10)
y = @. 2.5 * x + 3.0

# Create the problem and solve
prob = CurveFitProblem(x, y)
sol = solve(prob, LinearCurveFitAlgorithm())

# Access the coefficients: sol.u = (a, b)
println("Slope (a): ", sol.u[1])
println("Intercept (b): ", sol.u[2])

# Evaluate the solution at a point
println("Prediction at x=5: ", sol(5.0))
```

## Plotting with CairoMakie

Create plots using CairoMakie.jl with a 3-level structure (fig - axis - line):

```julia
using CSV, DataFrames
using CairoMakie

x = range(0, 10, length = 100)

# Create the wrapper `fig` with safeguarding padding 50
fig = Figure(figure_padding=50)

# Create an axis with title and labels
ax = Axis(fig[1, 1], title = "Line Plots", xlabel = "X", ylabel = "Y")

# Create a line plot, set color and label
lines!(ax, x, sin.(x), color = :red, label = "sin")

# Add another line plot to the same axis
lines!(ax, x, cos.(x), color = :blue, label = "cos")

# Add a legend at the bottom right with label size 15
# ALWAYS remember to add legends!
axislegend(ax; position = :rb, labelsize = 15)

# prevent contents from exceeding Figure frame, then save
# ALWAYS apply resize_to_layout to fig before saving!
resize_to_layout!(fig)
save("plot_lines6.pdf", fig)
println("sin plot generation success!")
fig
```

Use the `autolimitaspect` argument of `Axis` to tune the ratio between x and y axes when instructed. Always include an axis legend. After plotting, always save to a .pdf file with filename identical to the source .csv name.

## Error Report

All fittings should include an error report. The key metric is the **mean relative error** (as a percentage, unitless quantity), defined as `mean(|y - y_est| / y) * 100`, where `y` is the observed value and `y_est` is the predicted value.

### Case 1: Fitting target = original physical formula

When the fitting target function matches the physical formula directly, `residuals(sol)` returns values in the original physical units. Compute the mean relative error directly:

```julia
y_est = predict(sol)
rel_errs = abs.(residuals(sol)) ./ y
mean_rel_err_pct = mean(rel_errs) * 100
```

Equivalently, `abs.(y .- y_est) ./ y` gives the same element-wise relative errors.

### Case 2: Fitting target is a transform of the physical formula

When the fitting target function is a transformed version of the physical formula (e.g., a log-log target for a power-law physical relation), `residuals(sol)` and `predict(sol)` live in the **transformed** space. Using them directly for relative error is wrong because the units no longer match the original physical quantity. Instead, apply `predict()` then the **inverse transform** to recover predictions in the original space:

```julia
# Example: power law y = a * x^b
# Fitting target: log(y) = log(a) + b * log(x)
# Inverse transform: y_est = exp(predict(sol))

y_est = exp.(predict(sol))
rel_errs = abs.(y .- y_est) ./ y
mean_rel_err_pct = mean(rel_errs) * 100
```

The general pattern is: call `predict()` on the solution, apply the inverse of whatever transform was applied to obtain the fitting target, then compute relative errors against the original observed values.

### Note on StatsAPI

StatsAPI provides `residuals()`, `predict()`, `mse()`, `rmse()`, `r2()`, `confint()`, etc., but does **not** provide a built-in for mean relative/percentage error (MAPE). Always compute it manually as shown above.

## Julia CLI Usage

Execute Julia scripts and commands via CLI:

```bash
# Run a Julia script with the current project
julia --project=. FILE.jl

# Execute code directly in CLI mode using -e flag
julia --project=. -e 'using Pkg; Pkg.add(["CSV","DataFrames","CairoMakie","CurveFit"])'
```

The syntax for non-REPL mode (direct CLI mode) passes a string after the `-e` flag.

## Required Packages

Install necessary packages for data fitting workflows:

```bash
julia --project=. -e 'using Pkg; Pkg.add(["CSV","DataFrames","CairoMakie","CurveFit","Unitful","Measurements", "Statistics"])'
```
