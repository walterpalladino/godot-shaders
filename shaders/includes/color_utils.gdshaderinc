

//	Get color intensity (at pointgray scale)
float intensity_from_color(vec3 color)
{
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}
