package com.warriorofdeath.game

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import kotlin.math.hypot
import kotlin.random.Random

data class Mob(
    val id: Int,
    var pos: Offset,
    var hp: Float,
    val maxHp: Float,
    val speed: Float,
    val damage: Int,
    val xp: Int,
    val isBoss: Boolean = false
)

data class LootDrop(
    val id: Int,
    val pos: Offset,
    val name: String,
    val rarity: String,
    val bonus: Int
)

data class FloatText(
    val id: Int,
    var pos: Offset,
    val text: String,
    val color: Long,
    var ttl: Float = 1.0f
)

class GameState {
    var heroPos by mutableStateOf(Offset(500f, 500f))
    var heroTarget by mutableStateOf<Offset?>(null)
    var heroHp by mutableStateOf(100f)
    var heroMaxHp = 100f
    var heroLevel by mutableStateOf(1)
    var heroXp by mutableStateOf(0)
    var heroXpNext = 30
    var heroDamage = 12
    var attackCooldown by mutableStateOf(0f)
    var kills by mutableStateOf(0)
    var wave by mutableStateOf(1)
    var gold by mutableStateOf(0)
    var gameOver by mutableStateOf(false)

    val mobs = mutableStateListOf<Mob>()
    val loot = mutableStateListOf<LootDrop>()
    val texts = mutableStateListOf<FloatText>()
    private var nextId = 1

    fun startWave() {
        mobs.clear()
        val count = 3 + wave * 2
        repeat(count) {
            spawnMob(boss = false)
        }
        if (wave % 3 == 0) spawnMob(boss = true)
    }

    private fun spawnMob(boss: Boolean) {
        val angle = Random.nextFloat() * Math.PI.toFloat() * 2f
        val dist = if (boss) 500f else 380f + Random.nextFloat() * 250f
        val x = (heroPos.x + kotlin.math.cos(angle) * dist).coerceIn(40f, 960f)
        val y = (heroPos.y + kotlin.math.sin(angle) * dist).coerceIn(40f, 960f)
        val hp = if (boss) 120f + wave * 40f else 20f + wave * 8f
        mobs.add(
            Mob(
                id = nextId++,
                pos = Offset(x, y),
                hp = hp,
                maxHp = hp,
                speed = if (boss) 55f else 70f + wave * 3f,
                damage = if (boss) 12 + wave * 2 else 5 + wave,
                xp = if (boss) 40 + wave * 10 else 8 + wave * 2,
                isBoss = boss
            )
        )
    }

    fun update(dt: Float) {
        if (gameOver) return
        heroTarget?.let { target ->
            val d = target - heroPos
            val dist = hypot(d.x, d.y)
            if (dist < 8f) {
                heroTarget = null
            } else {
                val step = 260f * dt
                heroPos = heroPos + d / dist * minOf(step, dist)
            }
        }
        if (attackCooldown > 0f) attackCooldown -= dt
        val target = mobs.minByOrNull { (it.pos - heroPos).getDistance() }
        if (target != null && (target.pos - heroPos).getDistance() < 110f && attackCooldown <= 0f) {
            attackCooldown = 0.55f
            target.hp -= heroDamage + Random.nextInt(0, 5)
            addText(target.pos, "-${heroDamage}", 0xFFFFD54F)
            if (target.hp <= 0f) killMob(target)
        }
        for (mob in mobs.toList()) {
            val d = heroPos - mob.pos
            val dist = d.getDistance()
            if (dist > 46f) {
                val step = mob.speed * dt
                mob.pos = mob.pos + d / dist * minOf(step, dist - 40f)
            } else if (attackCooldown <= 0f) {
                heroHp -= mob.damage
                addText(heroPos, "-${mob.damage}", 0xFFEF5350)
                if (heroHp <= 0f) {
                    heroHp = 0f
                    gameOver = true
                }
            }
        }
        for (t in texts.toList()) {
            t.ttl -= dt
            t.pos = t.pos + Offset(0f, -40f * dt)
            if (t.ttl <= 0f) texts.remove(t)
        }
        if (mobs.isEmpty() && !gameOver) {
            wave++
            gold += 10 + wave * 2
            heroHp = minOf(heroMaxHp, heroHp + 25f)
            addText(heroPos, "Волна $wave", 0xFF64B5F6)
            startWave()
        }
    }

    private fun killMob(mob: Mob) {
        mobs.remove(mob)
        kills++
        heroXp += mob.xp
        val drop = Random.nextFloat()
        if (drop < 0.35f || mob.isBoss) {
            val rarities = listOf(
                Triple("Обычный", 0xFFBDBDBD, 1),
                Triple("Магический", 0xFF64B5F6, 3),
                Triple("Редкий", 0xFFFFD54F, 6)
            )
            val r = if (mob.isBoss) rarities[2] else rarities[Random.nextInt(0, 3)]
            loot.add(LootDrop(nextId++, mob.pos, "${r.first} клинок", r.first, r.third))
        }
        gold += if (mob.isBoss) 50 else 5
        addText(mob.pos, "+${mob.xp} XP", 0xFF81C784)
        while (heroXp >= heroXpNext) {
            heroXp -= heroXpNext
            heroLevel++
            heroXpNext = (heroXpNext * 1.5f).toInt()
            heroDamage += 3
            heroMaxHp += 15f
            heroHp = heroMaxHp
            addText(heroPos, "Уровень $heroLevel!", 0xFFFFD54F)
        }
    }

    fun pickupLoot() {
        for (item in loot.toList()) {
            if ((item.pos - heroPos).getDistance() < 70f) {
                loot.remove(item)
                heroDamage += item.bonus
                addText(heroPos, "+${item.name}", 0xFFFFD54F)
            }
        }
    }

    private fun addText(pos: Offset, text: String, color: Long) {
        texts.add(FloatText(nextId++, pos + Offset(0f, -30f), text, color))
        if (texts.size > 30) texts.removeAt(0)
    }

    fun restart() {
        heroPos = Offset(500f, 500f)
        heroTarget = null
        heroHp = 100f
        heroMaxHp = 100f
        heroLevel = 1
        heroXp = 0
        heroXpNext = 30
        heroDamage = 12
        kills = 0
        wave = 1
        gold = 0
        gameOver = false
        mobs.clear()
        loot.clear()
        texts.clear()
        startWave()
    }
}

private fun Offset.getDistance(): Float = hypot(x, y)
