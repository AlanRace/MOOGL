classdef SpectrumPanel < Panel
    
    properties (SetAccess = protected)        
        spectrumDisplay;
    end
    
    methods
        function this = SpectrumPanel(parent, spectrum)
            this = this@Panel(parent);
            
            this.spectrumDisplay = SpectrumDisplay(this, spectrum);
        end
    end
    
    methods(Access = protected)       
        function createPanel(this)
            createPanel@Panel(this);
        end
    end
end