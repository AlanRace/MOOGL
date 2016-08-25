% Class for storing spectral data. Couldn't use the name 'Spectrum' as it
% is used by MATLAB, so can cause confusion / unexpected behaviour
classdef SpectralData < Data
    properties (SetAccess = private)
        spectralChannels;
        intensities;
        
        isProfile = 0;
    end
    
    methods (Static)
        function vector = ensureColumnVector(vector)
            if(size(vector, 2) == 1)
                vector = vector';
            end
        end
    end
    
    methods
        function obj = SpectralData(spectralChannels, intensities)
            obj.spectralChannels = SpectralData.ensureColumnVector(spectralChannels);
            obj.intensities = SpectralData.ensureColumnVector(intensities);
        end
        
        function setIsProfile(obj, bool)
            obj.isProfile = bool;
        end
        
        function setData(this, spectralChannels, intensities)
            this.spectralChannels = SpectralData.ensureColumnVector(spectralChannels);
            this.intensities = SpectralData.ensureColumnVector(intensities);
            
            notify(this, 'DataChanged');
        end
        
        function obj = applyWorkflow(obj, preprocessingWorkflow)
            if(~isa(preprocessingWorkflow, 'PreprocessingWorkflow'))
                exception = MException('SpectralData:invalidArgument', 'Must provide an instance of a class that extends PreprocessingWorkflow');
                throw(exception);
            end
            
            [obj.spectralChannels, obj.intensities] = preprocessingWorkflow.performWorkflow(obj.spectralChannels, obj.intensities);
            notify(obj, 'DataChanged');
        end
        
        function exportToImage(obj)
            warning('TODO: Add functionality');
        end
        
        function exportToLaTeX(obj)
            warning('TODO: Add functionality');
        end
    end
end