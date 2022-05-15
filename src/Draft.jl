using GLMakie


values = Observable(Selafin.Get(data,1,1,1));
varnumber = Observable(1)
layernumber = Observable(1)
colorschoice = Observable(:viridis)
scientific = [:acton, :bamako, :batlow, :viridis]
timenumber = 1

fig = Figure(resolution = (1440, 1080))
ax = Axis(fig[1, 1])

mesh!([data.x[1:data.nbnodesLayer] data.y[1:data.nbnodesLayer]], data.ikle[1:data.nbtrianglesLayer, 1:3], color=values, colormap=colorschoice, shading=false)

time_slider = SliderGrid(fig[2, 1], (label = "Time step number", range = 1:1:data.nbsteps, startvalue = 1))
on(time_slider.sliders[1].value) do timeval
    values[] = Selafin.Get(data, varnumber.val, timeval, layernumber.val);
    global timenumber = timeval
end

varchoice = Menu(fig, options = data.varnames, prompt = "Variable name")
on(varchoice.selection) do selected_variable
    varnumber[] = findall(occursin.(selected_variable, data.varnames))[1]
    values[] = Selafin.Get(data,varnumber.val, timenumber, 1);
end

layerchoice = Menu(fig, options = 1:data.nblayers, prompt = "Layer number")
on(layerchoice.selection) do selected_layer
    layernumber[] = selected_layer
    values[] = Selafin.Get(data,varnumber.val, timenumber, layernumber.val);
end

colorchoice = Menu(fig, options = scientific, prompt = "Colors choice")
on(colorchoice.selection) do selected_color
    colorschoice[] = selected_color
    #values[] = Selafin.Get(data,varnumber.val, timenumber, layernumber.val);
end

fig[3,1] = hgrid!(
    Label(fig, "Variable:"), varchoice,
    Label(fig, "Layer:"), layerchoice,
    Label(fig, "Colors:"), colorchoice
)
