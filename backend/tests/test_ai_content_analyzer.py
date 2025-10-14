#!/usr/bin/env python3
"""
Unit tests for AI Content Analyzer
"""

import pytest
import sys
import os
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from file_organizer.ai_content_analyzer import AIContentAnalyzer


class TestMovieAnalysis:
    """Test movie filename parsing"""
    
    def test_movie_with_year_and_quality(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Thunderbolts.2025.German.TELESYNC.LD.720p.x265-LDO.mkv", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'movie'
        assert result['title'] == 'Thunderbolts'
        assert result['year'] == 2025
        assert result['quality'] == '720p'
        assert result['release_group'] == 'LDO'
        assert result['confidence_score'] >= 0.9
    
    def test_movie_1080p_bluray(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("The.Matrix.1999.1080p.BluRay.x264-YIFY.mp4", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'movie'
        assert result['title'] == 'The Matrix'
        assert result['year'] == 1999
        assert result['quality'] == '1080p'
        assert result['release_group'] == 'YIFY'
    
    def test_movie_parentheses_format(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Avatar (2009).mp4", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'movie'
        assert result['title'] == 'Avatar'
        assert result['year'] == 2009
    
    def test_movie_4k_quality(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Dune.2021.4K.HDR.x265-GROUP.mkv", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'movie'
        assert result['title'] == 'Dune'
        assert result['year'] == 2021
        assert result['quality'] == '4K'


class TestTVShowAnalysis:
    """Test TV show filename parsing"""
    
    def test_tvshow_sxxexx_format(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Breaking.Bad.S05E16.1080p.WEB-DL.mkv", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'tvshow'
        assert result['show_name'] == 'Breaking Bad'
        assert result['season'] == 5
        assert result['episode'] == 16
        assert result['confidence_score'] >= 0.9
    
    def test_tvshow_x_format(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Game.of.Thrones.8x06.mkv", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'tvshow'
        assert result['show_name'] == 'Game of Thrones'
        assert result['season'] == 8
        assert result['episode'] == 6


class TestArchiveAnalysis:
    """Test archive file analysis"""
    
    def test_zip_archive_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("project_backup.zip", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'archive'
        assert result['archive_type'] == 'zip'
        assert result['confidence_score'] >= 0.7
    
    def test_rar_archive_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("game_installer.rar", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'archive'
        assert result['archive_type'] == 'rar'
    
    def test_7z_archive_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("compressed.7z", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'archive'
        assert result['archive_type'] == '7z'


class TestImageAnalysis:
    """Test image file analysis"""
    
    def test_jpeg_image_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("photo.jpg", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'image'
        assert result['confidence_score'] >= 0.7
    
    def test_png_image_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("screenshot.png", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'image'


class TestDocumentAnalysis:
    """Test document file analysis"""
    
    def test_pdf_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("Invoice_2024.pdf", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'document'
        assert result['document_category'] == 'PDF'
    
    def test_docx_no_file(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("report.docx", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'document'


class TestQualityExtraction:
    """Test video quality extraction"""
    
    def test_extract_quality_patterns(self):
        analyzer = AIContentAnalyzer()
        
        assert analyzer._extract_quality("movie.2160p.mkv") == '2160p'
        assert analyzer._extract_quality("movie.4k.mkv") == '4K'
        assert analyzer._extract_quality("movie.1080p.mkv") == '1080p'
        assert analyzer._extract_quality("movie.720p.mkv") == '720p'
        assert analyzer._extract_quality("movie.480p.mkv") == '480p'
        assert analyzer._extract_quality("movie.TELESYNC.mkv") == 'TELESYNC'
        assert analyzer._extract_quality("movie.CAM.mkv") == 'CAM'
        assert analyzer._extract_quality("movie.BluRay.mkv") == 'BluRay'
        assert analyzer._extract_quality("movie.WEB-DL.mkv") == 'WEB-DL'
        assert analyzer._extract_quality("movie.WEBRip.mkv") == 'WEBRip'


class TestReleaseGroupExtraction:
    """Test release group extraction"""
    
    def test_extract_release_group(self):
        analyzer = AIContentAnalyzer()
        
        assert analyzer._extract_release_group("movie-YIFY.mkv") == 'YIFY'
        assert analyzer._extract_release_group("movie-SPARKS.mp4") == 'SPARKS'
        assert analyzer._extract_release_group("movie-LDO.mkv") == 'LDO'
        assert analyzer._extract_release_group("movie.mkv") is None


class TestUnknownFiles:
    """Test unknown file types"""
    
    def test_unknown_extension(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("file.xyz", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'unknown'
        assert result['file_extension'] == '.xyz'
        assert result['confidence_score'] == 0.5


class TestGenericVideo:
    """Test generic video files without metadata"""
    
    def test_generic_video(self):
        analyzer = AIContentAnalyzer()
        result = analyzer.analyze_file("family_vacation.avi", use_ai=False)
        
        assert result['success'] is True
        assert result['content_type'] == 'video'
        assert result['title'] == 'family_vacation.avi'
        assert result['confidence_score'] == 0.6


if __name__ == '__main__':
    pytest.main([__file__, '-v'])

