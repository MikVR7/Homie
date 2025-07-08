<script lang="ts">
	import { onMount } from 'svelte';
	import AIOrganizer from '$lib/components/file-organizer/AIOrganizer.svelte';
	import { homieStore } from '$lib/stores/homieStore';

	onMount(() => {
		homieStore.updateStatus('📂 File Organizer Module', 'info');
		homieStore.addLogEntry('📂 File Organizer module loaded', 'info');
	});
</script>

<svelte:head>
	<title>File Organizer - Homie</title>
	<meta name="description" content="AI-powered intelligent file organization and management" />
</svelte:head>

<main class="file-organizer-page">
	<div class="module-header">
		<h1>📂 File Organizer</h1>
	</div>

	<AIOrganizer />
</main>

<style>
	.file-organizer-page {
		padding: 1rem;
		max-width: 1200px;
		margin: 0 auto;
	}

	.module-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.module-header h1 {
		font-size: 2.5rem;
		margin: 0;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	@media (max-width: 768px) {
		.module-header h1 {
			font-size: 2rem;
		}
	}
</style> 