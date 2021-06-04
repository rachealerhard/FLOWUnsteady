#=##############################################################################
# DESCRIPTION
    Utilities

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Oct 2019
  * License   : MIT
=###############################################################################

# Color pallete for plots
clrs = [
            # [17, 20, 76]/255,
            [58, 150, 144]/255,
            [250, 188, 96]/255,
            [225, 98, 98]/255,
            [194, 232, 206]/255,
            [148, 170, 42]/255,
            [42, 148, 170]/255,
            [170, 42, 84]/255,
            [113, 145, 146]/255,
            [252, 127, 178]/255
        ]

dot(X, Y) = X[1]*Y[1] + X[2]*Y[2] + X[3]*Y[3]
norm(X) = sqrt(dot(X,X))

"""
    `plot_maneuver(maneuver::KinematicManeuver; ti::Real=0, tf::Real=1,
vis_nsteps=300, figname="maneuver", tstages=[])`

Plots the kinematics and controls of a `KinematicManeuver`.
"""
function plot_maneuver(maneuver::KinematicManeuver;
                        ti::Real=0, tf::Real=1, vis_nsteps=300,
                        save_path=nothing,
                        figname="maneuver", tstages=[], size_factor=2/3)

    Vvhcl = maneuver.Vvehicle
    avhcl = maneuver.anglevehicle
    ts = range(ti, tf, length=vis_nsteps)

    # -------------------- Vehicle velocity history ----------------------------
    fig1 = figure(figname*"-kinematics", figsize=[7*3, 5*1]*size_factor;
                                                        constrained_layout=true)
    axs1 = fig1.subplots(1, 3)

    # fig1.tight_layout()
    fig1.suptitle("VEHICLE KINEMATICS")

    ax = axs1[1]
    ax.title.set_text("Velocity")
    Vs = Vvhcl.(ts)
    Vmax = max([maximum([V[i] for V in Vs]) for i in 1:3]...)
    Vmin = min([minimum([V[i] for V in Vs]) for i in 1:3]...)

    ax.plot(ts, [V[1] for V in Vs], "-", label=L"V_x", alpha=0.8, color=clrs[1])
    ax.plot(ts, [V[2] for V in Vs], "-", label=L"V_y", alpha=0.8, color=clrs[2])
    ax.plot(ts, [V[3] for V in Vs], "-", label=L"V_z", alpha=0.8, color=clrs[3])

    for tstage in tstages
        ax.plot(tstage*ones(2), [Vmin, Vmax], ":k", alpha=0.5)
    end

    ax.set_xlabel("Non-dimensional time")
    ax.set_ylabel("Non-dimensional velocity")
    ax.legend(loc="best", frameon=false)

    # -------------------- Mission profile -------------------------------------
    Xinit = zeros(3)        # Initial position
    dt = ts[2]-ts[1]        # Time step

    Xs = [Xinit]
    for i in 1:(size(ts,1)-1)
        push!(Xs, Xs[end] + dt*Vs[i])
    end

    ax = axs1[2]
    ax.title.set_text("Position")
    Xmax = max([maximum([X[i] for X in Xs]) for i in 1:3]...)
    Xmin = min([minimum([X[i] for X in Xs]) for i in 1:3]...)

    ax.plot(ts, [X[1] for X in Xs], "-g", label=L"x", alpha=0.8, color=clrs[1])
    ax.plot(ts, [X[2] for X in Xs], "-b", label=L"y", alpha=0.8, color=clrs[2])
    ax.plot(ts, [X[3] for X in Xs], "-r", label=L"z", alpha=0.8, color=clrs[3])

    for tstage in tstages
        ax.plot(tstage*ones(2), [Xmin, Xmax], ":k", alpha=0.5)
    end

    ax.set_xlabel("Non-dimensional time")
    ax.set_ylabel("Non-dimensional position")
    ax.legend(loc="best", frameon=false)

    # -------------------- Vehicle angle history -------------------------------
    ax = axs1[3]
    ax.title.set_text("Angles")
    as = avhcl.(ts)
    amax = max([maximum([a[i] for a in as]) for i in 1:3]...)
    amin = min([minimum([a[i] for a in as]) for i in 1:3]...)

    ax.plot(ts, [a[1] for a in as], "-g", label=L"\theta_x", alpha=0.8, color=clrs[1])
    ax.plot(ts, [a[2] for a in as], "-b", label=L"\theta_y", alpha=0.8, color=clrs[2])
    ax.plot(ts, [a[3] for a in as], "-r", label=L"\theta_z", alpha=0.8, color=clrs[3])

    for tstage in tstages
        ax.plot(tstage*ones(2), [amin, amax], ":k", alpha=0.5)
    end

    ax.set_xlabel("Non-dimensional time")
    ax.set_ylabel(L"Angle ($^\circ$)")
    ax.legend(loc="best", frameon=false)

    if save_path!=nothing
        # Save figure
        fig1.savefig(joinpath(save_path, figname*"-kinematics.png"),
                                                transparent=false, dpi=300)
    end


    # -------------------- Tilting system history ------------------------------
    angle_syss = [a.(ts) for a in maneuver.angle]    # Angles of every tilt sys
    RPM_syss = [rpm.(ts) for rpm in maneuver.RPM]    # RPM of every rotor system

    nplots = 3*(length(angle_syss)!=0) + 1*(length(RPM_syss)!=0)
    gdims = nplots==4 ? [2, 2] : nplots==3 ? [2, 2] :
            nplots==1 ? [1, 1] : nplots==0 ? [0, 0] : [2, 2]
    gnum = gdims[1]*100 + gdims[2]*10
    ploti = 1

    if length(angle_syss)!=0 || length(RPM_syss)!=0
        fig2 = figure(figname*"-controls",
                        figsize=[7, 5].*gdims * size_factor * (nplots==1 ? 2/3 : 1);
                                                        constrained_layout=true)
        axs2 = fig2.subplots(gdims[1], gdims[2])
        axs2 = gdims[1]==1 && gdims[2]==1 ? [axs2] : axs2
        fig2.suptitle("VEHICLE CONTROLS")
    end

    if length(angle_syss)!=0
        for i in 1:3
            ax = axs2[ploti]
            ploti += 1

             # i-th angle of every tilting system
            a_syss = [[a[i] for a in angle_sys] for angle_sys in angle_syss]

            amax = max([maximum(a_sys) for a_sys in a_syss]...)
            amin = min([minimum(a_sys) for a_sys in a_syss]...)

            for tstage in tstages
                ax.plot(tstage*ones(2), [amin, amax], ":k", alpha=0.5)
            end

            for (j, a_sys) in enumerate(a_syss)
                ax.plot(ts, a_sys, "-", label="Tilt-sys #$j", alpha=0.8,
                                                color=clrs[(j-1)%length(clrs) + 1])
            end

            ax.set_xlabel("Non-dimensional time")
            ax.set_ylabel("Angle "*(i==1 ? L"\theta_x" : i==2 ? L"\theta_y" : L"\theta_z") * L" ($^\circ$)")
            ax.legend(loc="best", frameon=false)
        end
    end

    # -------------------- Rotor systems history -------------------------------

    if length(RPM_syss)!=0
        ax = axs2[ploti]
        ploti += 1

        RPMmax = max([maximum(RPM_sys) for RPM_sys in RPM_syss]...)
        RPMmin = min([minimum(RPM_sys) for RPM_sys in RPM_syss]...)

        for tstage in tstages
            ax.plot(tstage*ones(2), [RPMmin, RPMmax], ":k", alpha=0.5)
        end

        for (j, RPM_sys) in enumerate(RPM_syss)
            ax.plot(ts, RPM_sys, "-", label="Rotor-sys #$j", alpha=0.8,
                                            color=clrs[(j-1)%length(clrs) + 1])
        end

        ax.set_xlabel("Non-dimensional time")
        ax.set_ylabel("Non-dimensional RPM\n(RPM/RPMh)")
        ax.legend(loc="best", frameon=false)
    end

    if length(angle_syss)!=0 || length(RPM_syss)!=0
        if save_path!=nothing
            # Save figure
            fig2.savefig(joinpath(save_path, figname*"-controls.png"),
                                                    transparent=false, dpi=300)
        end
    end

end

"""
    `visualize_kinematics(sim::Simulation, nsteps::Int, save_path::String)`

Generate VTKs of the kinematics of this simulation.
"""
function visualize_kinematics(sim::Simulation{V, KinematicManeuver{N, M}, R},
                                nsteps::Int, save_path::String;
                                run_name="vis",
                                prompt=true,
                                verbose=true, v_lvl=0, verbose_nsteps=10,
                                paraview=true,
                                save_vtk_optsargs=[],
                              ) where {V<:AbstractVehicle, R<:Real, N, M}


    dt = sim.ttot/nsteps                # Time step

    # Create save path
    gt.create_path(save_path, prompt)
    strn = ""

    if verbose
        println("\t"^(v_lvl)*"*"^(73-7*v_lvl))
        println("\t"^(v_lvl)*"START $(joinpath(save_path,run_name))")
        println("\t"^(v_lvl)*"*"^(73-7*v_lvl))

        fig = figure(run_name, figsize=[7*2, 5*1]; constrained_layout=true)
        axs = fig.subplots(1, 3)
        ax = axs[1]
        ax.set_xlabel("Simulation time")
        ax.set_ylabel("Velocity")
        Vlbls = [L"V_x", L"V_y", L"V_z"]
        ax = axs[2]
        ax.set_xlabel("Simulation time")
        ax.set_ylabel(L"Angular velocity ($^\circ/t$)")
        Wlbls = [L"\Omega_x", L"\Omega_y", L"\Omega_z"]
        ax = axs[3]
        ax.set_xlabel("Simulation time")
        ax.set_ylabel(L"$O$ position")
        Olbls = [L"O_x", L"O_y", L"O_z"]
    end

    # Time stepping
    for i in 0:nsteps

        # if i!=0
            # Move tilting systems, and translate and rotate vehicle
            nextstep_kinematic(sim, dt)
            rotate_rotors(sim, dt)
        # end

        # Verbose
        if verbose && i%verbose_nsteps==0
            println("\t"^(v_lvl+1)*"Time step $i out of $nsteps")
        end
        if verbose
            for j in 1:3
                axs[1].plot(sim.t, sim.vehicle.V[j], ".", label=Vlbls[j], alpha=0.8,
                                                                color=clrs[j])
                axs[2].plot(sim.t, sim.vehicle.W[j], ".", label=Wlbls[j], alpha=0.8,
                                                                color=clrs[j])
                axs[3].plot(sim.t, sim.vehicle.system.O[j], ".", label=Olbls[j], alpha=0.8,
                                                                color=clrs[j])
            end
            if i==0
                for j in 1:3
                    axs[j].legend(loc="best", frameon=false)
                end
            end
        end

        strn = save_vtk(sim, run_name; path=save_path, save_vtk_optsargs...)
    end

    # Tweak vtk string to be a time sequence
    if nsteps>1
        strn = replace(strn, ".$(nsteps)."=>"...")
    end

    # Call paraview
    if paraview
        if verbose; println("\t"^(v_lvl)*"Calling Paraview..."); end
        run(`paraview --data="$save_path/$strn"`)
    end

    return strn
end
