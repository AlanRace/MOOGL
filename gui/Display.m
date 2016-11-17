classdef Display < handle
    properties (SetAccess = private)
        data;
        
        parent;
        axisHandle;
    end
    
    properties (Access = protected)
        dataListener;
        
        contextMenu;
        exportMenu;
        
        lastSavedPath = '';
    end

    events
        % 
        DisplayChanged;
    end
    
    methods
        function obj = Display(parent, data)
%             if(isempty(axisHandle) || ~(ishandle(axisHandle) && strcmp(get(axisHandle, 'Type'), 'axes')))

            if(isempty(parent) || (~isa(parent, 'Figure') && ~isa(parent, 'Panel')))
                exception = MException('Display:invalidArgument', '''parent'' must be a valid instance of Figure or Panel');
                throw(exception);
            end
            
            obj.parent = parent;
            parentHandle = parent.handle;
            
            obj.axisHandle = axes('Parent', parentHandle);
%             set(obj.axisHandle, 'ActivePositionProperty', 'OuterPosition');
            
            obj.setData(data);
            
            obj.createContextMenu();
            
            % Set up callbacks
            %set(get(obj.axisHandle, 'Parent'), 'UIContextMenu', obj.contextMenu);
            set(obj.axisHandle, 'UIContextMenu', obj.contextMenu);
        end
        
        function data = getData(this)
            data = this.data;
        end
        
        function setData(obj, data)
            if(~isa(data, 'Data'))
                exception = MException('Display:invalidArgument', 'Must provide an instance of a class that extends Data');
                throw(exception);
            end
            
            if(~isempty(obj.dataListener))
                delete(obj.dataListener);
            end
            
            obj.dataListener = addlistener(data, 'DataChanged', @(src, evnt)obj.updateDisplay());
            
            obj.data = data;
            obj.updateDisplay();
        end
        
        function createContextMenu(obj)
            parentHandle = obj.parent.getParentFigure().handle; %parent.handle;%
            
            % Set up the context menu
            obj.contextMenu = uicontextmenu('Parent', parentHandle);
            openInNewWindow = uimenu(obj.contextMenu, 'Label', 'Open in new window', 'Callback', @(src,evnt)obj.openInNewWindow());
            openCopyInNewWindow = uimenu(obj.contextMenu, 'Label', 'Open copy in new window', 'Callback', @(src,evnt)obj.openCopyInNewWindow());
            obj.exportMenu = uimenu(obj.contextMenu, 'Label', 'Export Data', 'Callback', []);
            
            if(~isdeployed())
                uimenu(obj.exportMenu, 'Label', 'To workspace', 'Callback', @(src,evnt)obj.data.exportToWorkspace());
            end
            
            uimenu(obj.exportMenu, 'Label', 'To MATLAB .mat file', 'Callback', @(src, evnt)obj.exportToMAT()); 
            uimenu(obj.exportMenu, 'Label', 'To PDF', 'Callback', @(src, evnt)obj.exportToImage());
%             uimenu(obj.exportMenu, 'Label', 'To LaTeX', 'Callback', @(src, evnt)obj.exportToLaTeX());
        end
        
        function exportToMAT(this)
            [fileName, pathName, filterIndex] = uiputfile([this.lastSavedPath 'data.mat'], 'Export data');
            
            if(filterIndex > 0)
                this.lastSavedPath = [pathName filesep];
                
                dataToExport = this.data;
                
                save([pathName filesep fileName], 'dataToExport');
            end
        end
        
        function disableContextMenu(this)
            delete(this.contextMenu);
            
            this.contextMenu = [];
        end
        
        
        function updateDisplay(this)
            notify(this, 'DisplayChanged');
        end
    end
    
    methods (Abstract)
        openInNewWindow(obj);
        openCopyInNewWindow(obj);
        
        exportToImage(obj);
        exportToLaTeX(obj);
    end
    
%     methods (Access = protected)
%         function buttonDownCallback(obj)
%             currentPoint = get(obj.axisHandle, 'CurrentPoint');
%             
%             xLimit = get(obj.axisHandle, 'xLim');
%             yLimit = get(obj.axisHandle, 'yLim');
%             
%             xPoint = currentPoint(1, 1);
%             yPoint = currentPoint(1, 2);
%             
%             mouseClick = get(get(obj.axisHandle, 'Parent'), 'SelectionType');
%             
%             mouseEvent = MouseEventData(MouseEventData.ButtonDown, xPoint, yPoint);
%             if(strcmp(mouseClick, 'normal'))
%                 mouseEvent.setButton(MouseEventData.LeftButton);
%             elseif(strcmp(mouseClick, 'alt'))
%                 mouseEvent.setButton(MouseEventData.RightButton);
%             end
%             
%             notify(obj, 'MouseDownInsideAxis', mouseEvent);
%         end
%     end
end