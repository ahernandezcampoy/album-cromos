<template>
  <div class="max-w-6xl mx-auto space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-gray-800">Mis Colecciones</h2>
      <button 
        @click="$emit('create')" 
        class="bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm px-4 py-2 rounded-xl shadow transition"
      >
        + Nueva Colección
      </button>
    </div>

    <div v-if="loading" class="text-center py-12 text-gray-500 font-semibold">
      Cargando colecciones...
    </div>

    <div v-else-if="collections.length === 0" class="bg-white p-12 rounded-2xl text-center border border-gray-200">
      <p class="text-gray-500 mb-4 text-lg">Aún no has creado ninguna colección de cromos.</p>
      <button 
        @click="$emit('create')" 
        class="bg-blue-600 text-white font-bold px-5 py-2.5 rounded-xl shadow hover:bg-blue-700 transition"
      >
        Crear la primera colección
      </button>
    </div>

    <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="col in collections" 
        :key="col.id"
        class="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition overflow-hidden flex flex-col justify-between"
      >
        <div class="p-5 flex gap-4">
          <!-- Portada -->
          <img 
            v-if="col.image_url" 
            :src="col.image_url" 
            :alt="col.title"
            @click="$emit('select', col.id)"
            class="w-24 h-32 object-cover rounded-lg shadow-sm border border-gray-200 flex-shrink-0 cursor-pointer hover:opacity-85 transition" 
          />
          <div 
            v-else 
            @click="$emit('select', col.id)"
            class="w-24 h-32 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400 font-bold flex-shrink-0 text-xs text-center p-2 cursor-pointer hover:border-blue-400 hover:text-blue-500 transition"
          >
            Sin Portada
          </div>

          <!-- Información -->
          <div class="flex-1 min-w-0 flex flex-col justify-between">
            <div>
              <span class="inline-block bg-blue-100 text-blue-800 text-xs font-bold px-2 py-0.5 rounded-full mb-1">
                {{ col.owner }}
              </span>
              <h3 class="font-bold text-gray-800 text-lg truncate" :title="col.title">{{ col.title }}</h3>
              <p class="text-xs text-gray-500 line-clamp-2 mt-1">{{ col.description || 'Sin descripción' }}</p>
            </div>

            <!-- Progreso -->
            <div class="mt-3">
              <div class="flex justify-between text-xs text-gray-600 font-semibold mb-1">
                <span>Progreso</span>
                <span>{{ col.progressPercentage }}%</span>
              </div>
              <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                <div 
                  class="bg-emerald-500 h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${col.progressPercentage}%` }"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Acciones -->
        <div class="bg-gray-50 px-5 py-3 border-t border-gray-100 flex justify-between items-center">
          <button 
            @click="$emit('edit', col.id)" 
            class="text-xs font-bold text-gray-600 hover:text-blue-600 transition flex items-center gap-1"
          >
            ✏️ Editar
          </button>
          <button 
            @click="$emit('select', col.id)" 
            class="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-4 py-1.5 rounded-lg transition"
          >
            Abrir Álbum →
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'

defineEmits(['select', 'create', 'edit'])

const loading = ref(true)
const collections = ref([])

const loadCollections = async () => {
  loading.value = true
  try {
    const { data: cols, error: colErr } = await supabase
      .from('collections')
      .select('*')
      .order('created_at', { ascending: false })

    if (colErr) throw colErr

    // Calcular progreso para cada colección
    const collectionsWithProgress = await Promise.all((cols || []).map(async (col) => {
      // 1. Grupos especiales
      const { data: groups } = await supabase
        .from('special_groups')
        .select('total')
        .eq('collection_id', col.id)
      
      const totalSpecial = (groups || []).reduce((acc, g) => acc + g.total, 0)
      const totalStickers = col.total_regular + totalSpecial

      // 2. Progreso conseguido
      const { data: prog } = await supabase
        .from('progress')
        .select('acquired')
        .eq('collection_id', col.id)
        .maybeSingle()

      const acquiredCount = prog?.acquired?.length || 0
      const pct = totalStickers > 0 ? Math.round((acquiredCount / totalStickers) * 100) : 0

      return {
        ...col,
        progressPercentage: pct
      }
    }))

    collections.value = collectionsWithProgress
  } catch (err) {
    console.error('Error cargando catálogo:', err)
  } finally {
    loading.value = false
  }
}

onMounted(loadCollections)
</script>