const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0b0b1b", /* black   */
  [1] = "#FA4F27", /* red     */
  [2] = "#FD7030", /* green   */
  [3] = "#C37746", /* yellow  */
  [4] = "#74836C", /* blue    */
  [5] = "#DE833F", /* magenta */
  [6] = "#FA8B39", /* cyan    */
  [7] = "#c2c2c6", /* white   */

  /* 8 bright colors */
  [8]  = "#5a5a6f",  /* black   */
  [9]  = "#FA4F27",  /* red     */
  [10] = "#FD7030", /* green   */
  [11] = "#C37746", /* yellow  */
  [12] = "#74836C", /* blue    */
  [13] = "#DE833F", /* magenta */
  [14] = "#FA8B39", /* cyan    */
  [15] = "#c2c2c6", /* white   */

  /* special colors */
  [256] = "#0b0b1b", /* background */
  [257] = "#c2c2c6", /* foreground */
  [258] = "#c2c2c6",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
