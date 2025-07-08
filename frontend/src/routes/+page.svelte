<script lang="ts">
	import { onMount } from 'svelte';
	import DiscoveryControls from '$lib/components/DiscoveryControls.svelte';
	import ResultsDisplay from '$lib/components/ResultsDisplay.svelte';
	import ActivityLog from '$lib/components/ActivityLog.svelte';
	import { homieStore } from '$lib/stores/homieStore';

	onMount(() => {
		console.log('🏠 Homie Frontend initialized');
		homieStore.addLogEntry('Frontend initialized - Ready to interact with Homie backend');
	});
</script>

<svelte:head>
	<title>🏠 Homie - File Organizer</title>
</svelte:head>

<div class="container">
	<header>
		<h1>🏠 Homie - Intelligent Home File Organizer</h1>
		<p>Easy interface to interact with your file organization backend</p>
	</header>

	<main>
		<DiscoveryControls />
		<ResultsDisplay />
		<ActivityLog />
	</main>
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
		color: #e2e8f0;
		min-height: 100vh;
		font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}

	.container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
		min-height: 100vh;
	}

	header {
		text-align: center;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 2px solid rgba(255, 255, 255, 0.1);
		background: rgba(255, 255, 255, 0.02);
		border-radius: 16px;
		padding: 2rem;
		backdrop-filter: blur(10px);
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
	}

	header h1 {
		color: #ffffff;
		margin: 0 0 0.5rem 0;
		font-size: 3rem;
		font-weight: 700;
		background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
		background-clip: text;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		text-shadow: 0 0 30px rgba(96, 165, 250, 0.3);
	}

	header p {
		color: #94a3b8;
		margin: 0;
		font-size: 1.2rem;
		font-weight: 400;
		opacity: 0.8;
	}

	main {
		display: flex;
		flex-direction: column;
		gap: 2rem;
	}

	@media (max-width: 768px) {
		.container {
			padding: 1rem;
		}

		header {
			margin-bottom: 2rem;
			padding: 1.5rem;
		}

		header h1 {
			font-size: 2.5rem;
		}

		header p {
			font-size: 1.1rem;
		}
	}
</style>
