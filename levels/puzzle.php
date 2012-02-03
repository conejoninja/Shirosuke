<?php


function puzzle($name) {
	
	
	
	$src = imagecreatefrompng($name.'.png');
	$dest = imagecreatetruecolor(64, 64);


	for($i=0;$i<5;$i++) {
		for($j=0;$j<=7;$j++) {
			if($j==7) { $mod = 32; } else { $mod = 0; };
			imagecopy($dest, $src, 0, 0, 64*$i-$mod, 64*$j-$mod, 64, 64);
			imagepng($dest,$name.$i.$j.".png");
		}
	}



	imagedestroy($dest);
	imagedestroy($src);
	
	echo "Se ha terminado de trozear el archivo ".$name.".png";


}

puzzle("level1");
puzzle("level2");
puzzle("level3");
puzzle("level4");
puzzle("level5");
puzzle("level6");
puzzle("level7");
puzzle("level8");
puzzle("level9");
puzzle("level10");
puzzle("tutorial");


?>
