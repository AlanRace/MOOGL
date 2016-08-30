classdef Panel < handle
    
    properties(SetAccess = protected)
        parent;
        
        panelHandle;
    end
    
    events
        WindowButtonMotion;
        WindowButtonUp;
    end
    
    methods
        function this = Panel(parent)
            if(~isa(parent, 'Figure') && ~isa(parent, 'Panel'))
                exception = MException('Panel:invalidArgument', '''parent'' must be a valid instance of Figure or Panel');
                throw(exception);
            end
            
            this.parent = parent;
            
            addlistener(parent, 'WindowButtonMotion', @(src, evnt) this.windowButtonMotion());
            addlistener(parent, 'WindowButtonUp', @(src, evnt) this.windowButtonUp());
            
            this.createPanel();
        end
    end
    
    methods(Access = protected)
        function createPanel(this)
            if(isa(this.parent, 'Figure'))
                parentHandle = this.parent.figureHandle;
            else
                parentHandle = this.parent.panelHandle;
            end
            
            uipanel(parentHandle);
        end
        
        function windowButtonMotion(this)
            notify(this, 'WindowButtonMotion');
        end
        
        function windowButtonUp(this)
            notify(this, 'WindowButtonUp');
        end
    end
end