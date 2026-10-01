package com.warriorofdeath.game

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun ArenaScreen() {
    val state = remember { GameState().also { it.startWave() } }
    val measurer = rememberTextMeasurer()

    LaunchedEffect(Unit) {
        var last = System.nanoTime()
        while (true) {
            val now = System.nanoTime()
            val dt = ((now - last) / 1_000_000_000f).coerceIn(0f, 0.05f)
            last = now
            state.update(dt)
            state.pickupLoot()
            delay(16)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text("Волна ${state.wave}", color = Color.White, fontSize = 16.sp)
            Text("Ур. ${state.heroLevel}  XP ${state.heroXp}/${state.heroXpNext}", color = Color.Gray, fontSize = 13.sp)
            Text("💰 ${state.gold}  ☠ ${state.kills}", color = Color.White, fontSize = 13.sp)
        }
        LinearProgressIndicator(
            progress = { (state.heroHp / state.heroMaxHp).coerceIn(0f, 1f) },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp)
        )
        Box(modifier = Modifier.weight(1f)) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        detectTapGestures { offset ->
                            state.heroTarget = offset
                        }
                    }
            ) {
                drawRect(Color(0xFF14171F))
                val gridStep = 80f
                var x = 0f
                while (x < size.width) {
                    drawLine(Color(0xFF1E2430), Offset(x, 0f), Offset(x, size.height), 1f)
                    x += gridStep
                }
                var y = 0f
                while (y < size.height) {
                    drawLine(Color(0xFF1E2430), Offset(0f, y), Offset(size.width, y), 1f)
                    y += gridStep
                }
                val scaleX = size.width / 1000f
                val scaleY = size.height / 1000f
                fun map(p: Offset) = Offset(p.x * scaleX, p.y * scaleY)
                for (drop in state.loot) {
                    val c = when (drop.rarity) {
                        "Редкий" -> Color(0xFFFFD54F)
                        "Магический" -> Color(0xFF64B5F6)
                        else -> Color(0xFFBDBDBD)
                    }
                    drawCircle(c, 10f, map(drop.pos))
                }
                state.heroTarget?.let { drawCircle(Color(0xFF64B5F6), 6f, map(it), alpha = 0.6f) }
                for (mob in state.mobs) {
                    val p = map(mob.pos)
                    val body = if (mob.isBoss) Color(0xFF8E24AA) else Color(0xFFC62828)
                    val r = if (mob.isBoss) 26f else 16f
                    drawCircle(body, r, p)
                    drawCircle(Color.Black, r, p, alpha = 0.25f)
                    val w = 44f
                    drawRect(Color.Black, p + Offset(-w / 2, -r - 12f), androidx.compose.ui.geometry.Size(w, 6f))
                    drawRect(
                        Color(0xFFEF5350),
                        p + Offset(-w / 2, -r - 12f),
                        androidx.compose.ui.geometry.Size(w * (mob.hp / mob.maxHp).coerceIn(0f, 1f), 6f)
                    )
                }
                val h = map(state.heroPos)
                drawCircle(Color(0xFF2E7D32), 20f, h)
                drawCircle(Color(0xFF81C784), 20f, h, alpha = 0.3f)
                drawCircle(Color.White, 5f, h + Offset(0f, -4f))
                for (t in state.texts) {
                    drawText(measurer, t.text, map(t.pos), color = Color(t.color))
                }
                if (state.gameOver) {
                    drawRect(Color.Black.copy(alpha = 0.7f))
                }
            }
            if (state.gameOver) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("Ты погиб на волне ${state.wave}", color = Color.White, fontSize = 22.sp)
                    Text("Убийств: ${state.kills}   Золото: ${state.gold}", color = Color.Gray, fontSize = 14.sp)
                    Button(onClick = { state.restart() }) {
                        Text("Ещё раз")
                    }
                }
            }
        }
        Text(
            "Тап — движение. Герой бьёт сам. Подбирай лут — растёт урон.",
            color = Color.Gray,
            fontSize = 12.sp,
            modifier = Modifier.padding(12.dp)
        )
    }
}
