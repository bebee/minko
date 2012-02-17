package aerys.minko.render
{
	import aerys.minko.ns.minko_render;
	import aerys.minko.render.resource.Program3DResource;
	import aerys.minko.type.Signal;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.geom.Rectangle;

	public final class RendererState
	{
		use namespace minko_render;
		
		private static const TMP_NUMBERS			: Vector.<Number>	= new Vector.<Number>(0xffff, true);
		private static const TMP_INTS				: Vector.<int>		= new Vector.<int>(0xffff, true);

		private static const BLENDING_STR			: Vector.<String>	= new <String>[
			Context3DBlendFactor.DESTINATION_ALPHA,
			Context3DBlendFactor.DESTINATION_COLOR,
			Context3DBlendFactor.ONE,
			Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA,
			Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR,
			Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA,
			Context3DBlendFactor.SOURCE_ALPHA,
			Context3DBlendFactor.SOURCE_COLOR,
			Context3DBlendFactor.ZERO
		];
		
		private var _priority			: Number				= 0.;
		
		private var _vertexConstants	: Vector.<Number>		= null;
		private var _fragmentConstants	: Vector.<Number>		= null;
		
		private var _renderTarget		: RenderTarget			= null;
		private var _program			: Program3DResource		= null;
		private var _compareMode		: String				= null;
		private var _enableDepthWrite	: Boolean				= true;
		private var _rectangle			: Rectangle				= null;
		
		private var _enabled			: Boolean				= true;
		
		private var _begin				: Signal				= new Signal();
		private var _end				: Signal				= new Signal();
		
		public function get priority():Number
		{
			return _priority;
		}
		public function set priority(value:Number):void
		{
			_priority = value;
		}

		public function get scissorRectangle() : Rectangle
		{
			return _rectangle;
		}
		public function set scissorRectangle(value : Rectangle) : void
		{
			_rectangle = value;
		}
		
		public function get compareMode() : String
		{
			return _compareMode;
		}
		public function set compareMode(value : String) : void
		{
			_compareMode = value;
		}
		
		public function get enableDepthWrite() : Boolean
		{
			return _enableDepthWrite;
		}
		public function set enableDepthWrite(value : Boolean) : void
		{
			_enableDepthWrite = value;
		}
		
		public function get program() : Program3DResource
		{
			return _program;
		}
		public function set program(value : Program3DResource) : void
		{
			_program = value;
		}
		
		public function get renderTarget() : RenderTarget
		{
			return _renderTarget;
		}
		public function set renderTarget(value : RenderTarget) : void
		{
			_renderTarget = value;
		}
		
		public function get enabled() : Boolean
		{
			return _enabled;
		}
		public function set enabled(value : Boolean) : void
		{
			_enabled = value;
		}

		public function get begin() : Signal
		{
			return _begin;
		}
		
		public function get end() : Signal
		{
			return _end;
		}
		
		public function RendererState() : void
		{
			initialize();
		}
		
		private function initialize() : void
		{
			_compareMode = Context3DCompareMode.LESS;
			_enableDepthWrite = true;
			_rectangle = null;
		}
		
		public function apply(context 		: Context3D,
							  backBuffer	: RenderTarget,
							  previous		: RendererState) : void
		{
			if (!previous || previous._renderTarget != _renderTarget)
			{
				if (_renderTarget)
				{
					context.setRenderToTexture(
						_renderTarget.resource.getNativeTexture(context),
						_renderTarget.useDepthAndStencil,
						_renderTarget.antiAliasing,
						_renderTarget.surfaceSelector
					);
				}
				else
				{
					context.setRenderToBackBuffer();
				}
				
				var rt : RenderTarget = _renderTarget || backBuffer;
				var color : uint = rt.backgroundColor;
				
				context.clear(
					((color >> 16) & 0xff) / 255.,
					((color >> 8) & 0xff) / 255.,
					(color & 0xff) / 255.,
					((color >> 24) & 0xff) / 255.
				);
			}
			
			context.setProgram(_program.getProgram3D(context));
			context.setScissorRectangle(_rectangle);
			context.setDepthTest(_enableDepthWrite, _compareMode);
		}
		
		public static function sort(states : Vector.<RendererState>, numStates : int) : void
		{
			if (numStates == 0)
				return;
			
			var n 		: int 			= numStates; // states.length;
			var i		: int 			= 0;
			var j		: int 			= 0;
			var k		: int 			= 0;
			var t		: int			= 0;
			var state 	: RendererState	= states[0];
			var anmin	: Number 		= -state._priority;
			var nmax	: int  			= 0;
			var p		: Number		= 0.;
			var sorted	: Boolean		= true;
			
			for (i = 0; i < n; ++i)
			{
				state = states[i];
				p = -state._priority;
				
				TMP_INTS[i] = 0;
				TMP_NUMBERS[i] = p;
				if (p < anmin)
					anmin = p;
				else if (p > Number(TMP_NUMBERS[nmax]))
					nmax = i;
			}
			
			if (anmin == Number(TMP_NUMBERS[nmax]))
				return ;
			
			var m		: int 	= Math.ceil(n * .125);
			var nmove	: int 	= 0;
			var c1		: Number = (m - 1) / (Number(TMP_NUMBERS[nmax]) - anmin);
			
			for (i = 0; i < n; ++i)
			{
				k = int(c1 * (Number(TMP_NUMBERS[i]) - anmin));
				TMP_INTS[k] = int(TMP_INTS[k]) + 1;
			}
			
			for (k = 1; k < m; ++k)
				TMP_INTS[k] = int(TMP_INTS[k]) + int(TMP_INTS[int(k - 1)]);
			
			var hold		: Number 		= Number(TMP_NUMBERS[nmax]);
			var holdState 	: RendererState = states[nmax];
			
			TMP_NUMBERS[nmax] = Number(TMP_NUMBERS[0]);
			TMP_NUMBERS[0] = hold;
			states[nmax] = states[0];
			states[0] = holdState;
			
			var flash		: Number		= 0.;
			var flashState	: RendererState	= null;
			
			j = 0;
			k = int(m - 1);
			i = int(n - 1);
			
			while (nmove < i)
			{
				while (j > int(TMP_INTS[k]) - 1)
				{
					++j;
					k = int(c1 * (Number(TMP_NUMBERS[j]) - anmin));
				}
				
				flash = Number(TMP_NUMBERS[j]);
				flashState = RendererState(states[j]);
				
				while (!(j == int(TMP_INTS[k])))
				{
					k = int(c1 * (flash - anmin));
					
					t = int(TMP_INTS[k]) - 1;
					hold = Number(TMP_NUMBERS[t]);
					holdState = RendererState(states[t]);
					
					TMP_NUMBERS[t] = flash;
					states[t] = flashState;
					
					flash = hold;
					flashState = holdState;
					
					TMP_INTS[k] = int(TMP_INTS[k]) - 1;
					++nmove;
				}
			}
			
			for (j = 1; j < n; ++j)
			{
				hold = Number(TMP_NUMBERS[j]);
				holdState = states[j];
				
				i = int(j - 1);
				while (i >= 0 && Number(TMP_NUMBERS[i]) > hold)
				{
					// not trivial
					TMP_NUMBERS[int(i + 1)] = Number(TMP_NUMBERS[i]);
					states[int(i + 1)] = states[i];
					
					--i;
				}
				
				TMP_NUMBERS[int(i + 1)] = hold;
				states[int(i + 1)] = holdState;
			}
		}
	}
}