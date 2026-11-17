function fig = plot_chromaclimber_bicone(input)
%PLOT_CHROMACLIMBER_BICONE Interactive 3-D color plot with condition filters.
%   plot_chromaclimber_bicone
%   plot_chromaclimber_bicone('ChromaClimber_Cleaned.csv')
%   plot_chromaclimber_bicone(T)
%
% Uses the table's logged calibrated H/L/S, NOT RGB/255 and NOT a second
% black-white-red fit. A separately labeled raw-derived view is available.
% Drag the axes to rotate; use the toolbar to zoom. Export saves a 300-dpi
% PNG. Requires base MATLAB R2020a+ for exportgraphics; no add-on toolbox.

base=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(input), input=fullfile(base,'ChromaClimber_Cleaned.csv'); end
if istable(input)
    T=input;
else
    file=string(input); assert(isfile(file),'Cannot find cleaned file: %s',file);
    [~,~,ext]=fileparts(file);
    if strcmpi(ext,'.xlsx')
        T=readtable(file,'Sheet','Readings','TextType','string');
    else
        T=readtable(file,'TextType','string');
    end
end
[T,~]=chromaclimber_coordinates(T); % Also verifies and recalculates coordinates.
T.TrueColor=string(T.TrueColor);
colorNames=["Black";"White";"Red";"Yellow";"Green";"Cyan";"Blue";"Magenta"];
colors=[0 0 0;1 1 1;1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
roomOptions=["All environments";unique(T.Room)];
lightingOptions=["On + off";"on";"off"];
timeOptions=["All integration times";"60 ms";"300 ms";"600 ms"];
repOptions=["Calibrated (logged)";"Raw RGB (derived)"];
scaleOptions=["Within each condition";"Fixed pooled bounds"];
pointOptions=["Every sample";"Condition/color centroids"];
colorOptions=["All colors";colorNames];

fig=figure('Name','ChromaClimber - Color bicone','NumberTitle','off', ...
    'Color','w','Position',[70 60 1320 880]);
ax=axes('Parent',fig,'Units','normalized','Position',[.07 .16 .86 .64]);
view(ax,-35,20);
makeLabel('Environment',.02,.17);
roomUI=makePopup(roomOptions,.02,.17);
makeLabel('Room lights',.20,.10);
lightUI=makePopup(lightingOptions,.20,.10);
makeLabel('Integration time',.31,.14);
timeUI=makePopup(timeOptions,.31,.14);
makeLabel('Representation',.46,.19);
repUI=makePopup(repOptions,.46,.19);
makeLabel('Lightness scaling',.66,.18);
scaleUI=makePopup(scaleOptions,.66,.18);
makeLabel('Points',.85,.13);
pointUI=makePopup(pointOptions,.85,.13);

colorUI=uicontrol(fig,'Style','popupmenu','String',cellstr(colorOptions), ...
    'Units','normalized','Position',[.02 .844 .15 .04],'Callback',@(~,~)redraw());
errorsUI=uicontrol(fig,'Style','checkbox','String','Misclassified only', ...
    'Units','normalized','Position',[.20 .844 .17 .04],'BackgroundColor','w','Callback',@(~,~)redraw());
targetUI=uicontrol(fig,'Style','checkbox','String','Nominal targets','Value',1, ...
    'Units','normalized','Position',[.40 .844 .15 .04],'BackgroundColor','w','Callback',@(~,~)redraw());
shellUI=uicontrol(fig,'Style','checkbox','String','Bicone shell','Value',1, ...
    'Units','normalized','Position',[.58 .844 .14 .04],'BackgroundColor','w','Callback',@(~,~)redraw());
uicontrol(fig,'Style','pushbutton','String','Reset view','Units','normalized', ...
    'Position',[.74 .844 .10 .04],'Callback',@(~,~)resetView());
uicontrol(fig,'Style','pushbutton','String','Export PNG','Units','normalized', ...
    'Position',[.86 .844 .12 .04],'Callback',@(~,~)savePNG());
info=uicontrol(fig,'Style','text','Units','normalized','Position',[.04 .025 .92 .10], ...
    'HorizontalAlignment','left','BackgroundColor','w','FontSize',11);
redraw();
rotate3d(fig,'on');

    function makeLabel(label,x,w)
        uicontrol(fig,'Style','text','String',label,'Units','normalized', ...
            'Position',[x .948 w .025],'HorizontalAlignment','left', ...
            'BackgroundColor','w','FontWeight','bold');
    end
    function ui=makePopup(options,x,w)
        ui=uicontrol(fig,'Style','popupmenu','String',cellstr(options), ...
            'Units','normalized','Position',[x .900 w .044], ...
            'Callback',@(~,~)redraw());
    end
    function resetView()
        view(ax,-35,20); axis(ax,[-1.15 1.15 -1.15 1.15 -1.15 1.15]);
    end
    function redraw()
        keep=true(height(T),1);
        if roomUI.Value>1, keep=keep & T.Room==roomOptions(roomUI.Value); end
        if lightUI.Value>1, keep=keep & T.AmbientLight==lightingOptions(lightUI.Value); end
        times=[60 300 600];
        if timeUI.Value>1, keep=keep & T.Integration_ms==times(timeUI.Value-1); end
        if colorUI.Value>1, keep=keep & T.TrueIndex==colorUI.Value-2; end
        selected=keep;
        if errorsUI.Value, keep=keep & T.Correct==0; end
        raw=repUI.Value==2;
        if raw
            H=T.RawHue; S=T.RawSaturation; L=T.RawLightness; Ln=T.RawLNorm;
        else
            H=T.HueWrapped; S=T.SaturationLogged; L=T.LightnessLogged; Ln=T.CalLNorm;
        end
        if scaleUI.Value==2
            lo=min(L); hi=max(L); % Entire input dataset, NOT just selected colors.
            if hi>lo, Ln=(L-lo)/(hi-lo); else, Ln=0.5*ones(size(L)); end
        end
        Z=2*Ln-1; R=(1-abs(Z)).*S;
        X=R.*cos(2*pi*H); Y=R.*sin(2*pi*H);
        [az,ev]=view(ax); cla(ax); hold(ax,'on');
        if shellUI.Value
            [h,l]=meshgrid(linspace(0,1,73),linspace(0,1,25));
            z=2*l-1; r=1-abs(z);
            texture=hslShellRGB(h,l);
            surf(ax,r.*cos(2*pi*h),r.*sin(2*pi*h),z,texture, ...
                'EdgeColor','none','FaceColor','texturemap','FaceAlpha',.12, ...
                'HandleVisibility','off');
        end
        for hh=0:1/12:11/12
            zz=linspace(-1,1,41); rr=1-abs(zz);
            plot3(ax,rr*cos(2*pi*hh),rr*sin(2*pi*hh),zz, ...
                'Color',[.78 .82 .85],'LineWidth',.4,'HandleVisibility','off');
        end
        theta=linspace(0,2*pi,145);
        for zz=[-.5 0 .5]
            rr=1-abs(zz);
            plot3(ax,rr*cos(theta),rr*sin(theta),zz*ones(size(theta)), ...
                'Color',[.72 .78 .82],'LineWidth',.5,'HandleVisibility','off');
        end
        if pointUI.Value==1
            for k=0:7
                for correct=[1 0]
                    idx=find(keep & T.TrueIndex==k & T.Correct==correct);
                    if isempty(idx), continue; end
                    if correct
                        p=scatter3(ax,X(idx),Y(idx),Z(idx),20,colors(k+1,:), ...
                            'filled','MarkerEdgeColor',[.2 .27 .30], ...
                            'MarkerFaceAlpha',.8,'HandleVisibility','off');
                    else
                        p=scatter3(ax,X(idx),Y(idx),Z(idx),45,colors(k+1,:), ...
                            'x','LineWidth',1.3,'HandleVisibility','off');
                    end
                    % Numeric data tips work on releases supporting DataTipTemplate.
                    if isprop(p,'DataTipTemplate')
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Record ID',T.RecordID(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Integration (ms)',T.Integration_ms(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('True color index',T.TrueIndex(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Logged prediction',T.PredictedIndex(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Hue',H(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Normalized L',Ln(idx));
                        p.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Saturation',S(idx));
                    end
                end
            end
        elseif any(keep)
            key=T.Condition(keep)+" | "+T.TrueColor(keep);
            [~,~,g]=unique(key);
            x=splitapply(@mean,X(keep),g); y=splitapply(@mean,Y(keep),g);
            z=splitapply(@mean,Z(keep),g);
            colorIndex=splitapply(@(v)v(1),T.TrueIndex(keep),g);
            scatter3(ax,x,y,z,65,colors(colorIndex+1,:),'s','filled', ...
                'MarkerEdgeColor',[.2 .27 .30],'HandleVisibility','off');
        end
        if targetUI.Value
            nominalH=[0 0 0 1/6 1/3 .5 2/3 5/6];
            for k=1:8
                if colorUI.Value>1 && k~=colorUI.Value-1, continue; end
                if k==1, z=-1; r=0; elseif k==2, z=1; r=0; else, z=0; r=1; end
                x=r*cos(2*pi*nominalH(k)); y=r*sin(2*pi*nominalH(k));
                scatter3(ax,x,y,z,72,colors(k,:),'d','filled', ...
                    'MarkerEdgeColor',[.12 .18 .22],'LineWidth',1.0,'HandleVisibility','off');
                text(ax,x,y,z+.055,colorNames(k),'FontSize',9,'Color',[.18 .28 .36]);
            end
        end
        axis(ax,'equal'); axis(ax,[-1.15 1.15 -1.15 1.15 -1.15 1.15]);
        grid(ax,'on'); box(ax,'on'); view(ax,az,ev);
        xlabel(ax,'x = r cos(2\piH)'); ylabel(ax,'y = r sin(2\piH)'); zlabel(ax,'z = 2L_n - 1');
        title(ax,{char(repOptions(repUI.Value)), ...
            sprintf('%s | %s | %s',roomOptions(roomUI.Value),lightingOptions(lightUI.Value),timeOptions(timeUI.Value))}, ...
            'Interpreter','none');
        if any(selected), accuracy=100*mean(T.Correct(selected)); else, accuracy=NaN; end
        info.String=sprintf(['%d selected samples | logged classifier accuracy %.1f%% | %d samples shown\n' ...
            'Point color = intended color. Circles = correct, x = incorrect, diamonds = nominal targets.\n' ...
            '%s. Raw view uses the same runs, not the earlier 13-classroom data. No jitter or second calibration.'], ...
            sum(selected),accuracy,sum(keep),scaleOptions(scaleUI.Value));
        drawnow;
    end
    function savePNG()
        [name,folder]=uiputfile('*.png','Save bicone','ChromaClimber_Bicone.png');
        if isequal(name,0), return; end
        exportgraphics(ax,fullfile(folder,name),'Resolution',300,'BackgroundColor','white');
    end
end

function rgb=hslShellRGB(h,l)
% Standard HSL S=1 colors are used only to tint the geometric reference shell.
% This does not change the firmware saturation used for measurement positions.
c=1-abs(2*l-1); h6=6*mod(h,1); x=c.*(1-abs(mod(h6,2)-1));
r=zeros(size(h)); g=r; b=r;
a=h6<1; r(a)=c(a); g(a)=x(a);
a=h6>=1 & h6<2; r(a)=x(a); g(a)=c(a);
a=h6>=2 & h6<3; g(a)=c(a); b(a)=x(a);
a=h6>=3 & h6<4; g(a)=x(a); b(a)=c(a);
a=h6>=4 & h6<5; r(a)=x(a); b(a)=c(a);
a=h6>=5; r(a)=c(a); b(a)=x(a);
m=l-c/2; rgb=cat(3,r+m,g+m,b+m);
end
