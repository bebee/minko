package aerys.minko.render
{
	import aerys.minko.ns.minko_render;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.type.Signal;
	import aerys.minko.type.binding.DataBindings;

	/**
	 * The base class to define effects.
	 *  
	 * @author Jean-Marc Le Roux
	 * 
	 */
	public class Effect
	{
		private var _passes			: Vector.<Shader>	= null;
		private var _passesChanged	: Signal			= new Signal('Effect.passesChanged');
		
		public function get passesChanged() : Signal
		{
			return _passesChanged;
		}
		
		public function get numPasses() : uint
		{
			return _passes.length;
		}
		
		public function Effect(...passes)
		{
			initialize(passes);
		}
		
		private function initialize(passes : Array) : void
		{
			while (passes[0] is Array)
				passes = passes[0];
			
			_passes = Vector.<Shader>(passes);
		}
		
		public function getPass(index : uint = 0) : Shader
		{
			return _passes[index];
		}
		
		public function setPasses(newPasses : Vector.<Shader>) : Effect
		{
			_passes = newPasses.slice();
			_passesChanged.execute(this);
			
			return this;
		}
		
		public function addPass(pass : Shader) : Effect
		{
			if (hasPass(pass))
				throw new Error('This pass is already in the effect.');
			
			_passes.push(pass);
			_passesChanged.execute(this);
			
			return this;
		}
		
		public function removePass(pass : Shader) : Effect
		{
			var numPasses 	: int 	= _passes.length - 1;
			var index		: int	= _passes.indexOf(pass);
			
			if (index < 0)
				throw new Error('This pass does not exists.');
			
			for (; index < numPasses; index++)
				_passes[index] = _passes[int(index + 1)];
			
			_passes.length = numPasses;
			
			_passesChanged.execute(this);
			
			return this;
		}
		
		public function hasPass(pass : Shader) : Boolean
		{
			return _passes.indexOf(pass) >= 0;
		}
		
		public function clone() : Effect
		{
			return new Effect().setPasses(_passes);
		}
	}
}
