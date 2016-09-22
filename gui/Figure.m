classdef Figure < handle
    % Figure Base class to handle common GUI properties and actions.
    
    properties (SetAccess = protected)
        % MATLAB figure handle
        figureHandle = [];
    end
    
    events
        % Triggered when user attempts to close the figure
        CloseRequested;
        % Triggered after figure is closed
        FigureClosed;
        % Triggered when an information message is created
        InfoMessage;
        
        WindowButtonMotion;
        WindowButtonUp;
    end
    
    methods
        function this = Figure()
            % Figure Create figure window.
            
            this.createFigure();
        end
        
        function setTitle(this, title)
            % setTitle Set the title of the figure window.
            %
            %   setTitle(title)
            %       title - Title to assign.
            
            set(this.figureHandle, 'Name', title);
        end
        
        function delete(this)
            % delete Close and delete the figure.
            %
            %   delete()
            %
            %   The 'FigureClosed' event will be triggered prior to
            %   deleting the figure handle.
            
            notify(this, 'FigureClosed');
            
            if(this.figureHandle ~= 0)
                delete(this.figureHandle);
            end
            
            this.figureHandle = 0;
        end
        
        function closeRequest(this)
            % closeRequest Trigger the 'CloseRequested' event and then delete the figure.
            %
            %   closeRequest()
            %
            
            notify(this, 'CloseRequested');
            
            this.delete();
        end
        
        function figure = getParentFigure(this)
            figure = this;
        end
    end
    
    methods (Access = protected)
        
        function createFigure(this)
            % createFigure Create figure.
            %
            %   createFigure()
            if(isempty(this.figureHandle))
                this.figureHandle = figure(...
                    'Name', 'Figure', 'NumberTitle','off',...
                    'Units','characters',...
                    'MenuBar','none',...
                    'Toolbar','none', ...
                    'CloseRequestFcn', @(src, evnt)this.closeRequest(), ...
                    'WindowButtonMotionFcn', @(src, evnt)this.windowButtonMotion(), ...
                    'WindowButtonUpFcn', @(src, evnt)this.windowButtonUp());
                
                % Set the callback for when the window is resized
                if(isprop(this.figureHandle, 'SizeChangedFcn'))
                    set(this.figureHandle, 'SizeChangedFcn', @(src, evnt)this.sizeChanged());
                else
                    set(this.figureHandle, 'ResizeFcn', @(src, evnt)this.sizeChanged());
                end 
            end
            
            this.createMenu();
        end
        
        function windowButtonMotion(this)
            notify(this, 'WindowButtonMotion');
        end
        
        function windowButtonUp(this)
            notify(this, 'WindowButtonUp');
        end
        
        function createMenu(this)
            % createMenu Create and add a menu to the figure.
            %
            %    createMenu()
        end
        
        function sizeChanged(this)
            % sizeChanged Callback function for when figure size is changed.
            %
            %   sizeChanged()
        end
    end
    
    methods (Static)
        function position = getPositionInPixels(object) 
            % getPositionInPixels  Get the position of the object within 
            % the figure in pixels.
            %
            %    position = getPositionInPixels(object) 
            
            
            oldUnits = get(object, 'Units');
            set(object, 'Units', 'pixels');
            
            position = get(object, 'Position');
            set(object, 'Units', oldUnits);
        end
        
        function setObjectPositionInPixels(object, newPosition)
            % setObjectPositionInPixels Set the position of object in 
            % pixels.
            %
            %   setObjectPositionInPixels(object, newPosition) 
            
            % Ensure that we're setting the size to a valid one
            if(newPosition(3) > 0 && newPosition(4) > 0)
                oldUnits = get(object, 'Units');
                set(object, 'Units', 'pixels');
                set(object, 'Position', newPosition);
                set(object, 'Units', oldUnits);
            end
        end
    end
    
end