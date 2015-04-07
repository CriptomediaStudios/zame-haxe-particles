package org.zamedev.particles.renderers;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import openfl.display.Tilesheet;
import openfl.display3D.Context3DRenderMode;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;

/**
 * Stage3DRenderer
 * dependency https://github.com/as3boyan/TilesheetStage3D
 * @usage Call TilesheetStage3D.init(stage, 0, 5, onInit, Context3DRenderMode.AUTO); before DefaultParticleRenderer.createInstance(); (put this inside onInit function)
 * @author loudo
 */
class Stage3DRenderer extends DrawTilesParticleRenderer 
{
	private static inline var TILE_DATA_FIELDS = 9; // x, y, tileId, scale, rotation, red, green, blue, alpha
	
	public function new() 
	{
		super();
	
	}
	
	override public function addParticleSystem(ps:ParticleSystem):Void {
		
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();
		
		ps.textureBitmapData = TilesheetStage3D.fixTextureSize( ps.textureBitmapData, true );

        var tilesheet = new TilesheetStage3D(ps.textureBitmapData);

        tilesheet.addTileRect(
            ps.textureBitmapData.rect.clone(),
            new Point(ps.textureBitmapData.rect.width / 2, ps.textureBitmapData.rect.height / 2)
        );

        var tileData = new Array<Float>();
        tileData[Std.int(ps.maxParticles * TILE_DATA_FIELDS - 1)] = 0.0; // Std.int(...) required for neko

        dataList.push({
            ps: ps,
            tilesheet: tilesheet,
            tileData: tileData,
            updated: false,
        });
    }
	
	override  private function onEnterFrame(_):Void {
        var updated = false;

        for (data in dataList) {
            if (data.updated = data.ps.__update()) {
                updated = true;
            }
        }

        #if (html5 && dom)
            if (styleIsDirty && __style != null) {
                __style.setProperty("pointer-events", "none", null);
            } else if (!styleIsDirty && __style == null) {
                styleIsDirty = true;
            }
        #end

        if (!updated) {
            return;
        }
		
		TilesheetStage3D.clearGraphic( graphics );

        graphics.clear();

        for (data in dataList) {
            if (!data.updated) {
                continue;
            }

            var ps = data.ps;
            var tileData = data.tileData;
            var index:Int = 0;
            var ethalonSize:Float = ps.textureBitmapData.width;

            var flags = (ps.blendFuncSource == GL.SRC_ALPHA && ps.blendFuncDestination == GL.ONE
                ? Tilesheet.TILE_BLEND_ADD
                : Tilesheet.TILE_BLEND_NORMAL
            );

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];

                tileData[index] = particle.position.x * ps.particleScaleX; // x
                tileData[index + 1] = particle.position.y * ps.particleScaleY; // y
                tileData[index + 2] = 0.0; // tileId
                tileData[index + 3] = particle.particleSize / ethalonSize * ps.particleScaleSize; // scale
                tileData[index + 4] = particle.rotation #if flash + Math.PI * 0.5 #end ; // rotation
                tileData[index + 5] = particle.color.r;
                tileData[index + 6] = particle.color.g;
                tileData[index + 7] = particle.color.b;
                tileData[index + 8] = particle.color.a;

                index += TILE_DATA_FIELDS;
            }

            data.tilesheet.drawTiles(
                graphics,
                tileData,
                true,
                Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION | Tilesheet.TILE_RGB | Tilesheet.TILE_ALPHA | flags,
                index
            );
        }
    }
	
}