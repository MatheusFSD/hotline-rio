import bpy, addon_utils
addon_utils.enable('blender_mcp', default_set=False)
import blender_mcp
if not getattr(bpy.types, 'blendermcp_server', None):
    bpy.types.blendermcp_server = blender_mcp.BlenderMCPServer(port=9876)
bpy.types.blendermcp_server.start()
